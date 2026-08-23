// NCDB FTP Client
// A minimal but real FTP/FTPS client built on Network.framework.
//
// Supports plain FTP and implicit FTPS (TLS from connect, conventionally port
// 990). Explicit FTPS (AUTH TLS) is not supported: Network.framework cannot
// upgrade an established NWConnection to TLS in place.
//
// SFTP (SSH File Transfer Protocol) is a different protocol entirely and would
// require an SSH implementation. It is not supported here, and the UI no longer
// claims otherwise.

import Foundation
import Network

// MARK: - Continuation Box

/// Serialises resumption of a continuation driven by Network.framework callbacks,
/// which arrive on a dispatch queue rather than in actor context.
private nonisolated final class ContinuationBox<T>: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<T, Error>?

    init(_ continuation: sending CheckedContinuation<T, Error>) {
        self.continuation = continuation
    }

    func resume(returning value: sending T) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(returning: value)
    }

    func resume(throwing error: Error) {
        lock.lock()
        let pending = continuation
        continuation = nil
        lock.unlock()
        pending?.resume(throwing: error)
    }
}

// MARK: - FTP Client

actor FTPClient {

    // MARK: Configuration

    struct Configuration: Sendable {
        var host: String
        var port: Int
        var username: String
        var password: String
        /// Implicit TLS from the moment of connection.
        var useTLS: Bool
        /// Remote directory the site is published into, e.g. "/public_html".
        var remotePath: String
    }

    // MARK: Errors

    enum FTPClientError: LocalizedError {
        case notConnected
        case connectionFailed(String)
        case authenticationFailed(String)
        case unexpectedResponse(code: Int, message: String)
        case passiveModeFailed(String)
        case transferFailed(String)
        case connectionClosed

        var errorDescription: String? {
            switch self {
            case .notConnected:
                return "Not connected to the server."
            case .connectionFailed(let detail):
                return "Couldn't reach the server: \(detail)"
            case .authenticationFailed(let detail):
                return "The server rejected those credentials: \(detail)"
            case .unexpectedResponse(let code, let message):
                return "Server replied \(code): \(message)"
            case .passiveModeFailed(let detail):
                return "Couldn't open a data connection: \(detail)"
            case .transferFailed(let detail):
                return "Transfer failed: \(detail)"
            case .connectionClosed:
                return "The server closed the connection."
            }
        }
    }

    /// One line of FTP reply.
    struct Response: Sendable {
        let code: Int
        let message: String

        var isPositive: Bool { (200...399).contains(code) }
    }

    // MARK: State

    private let configuration: Configuration
    private let queue = DispatchQueue(label: "com.ncdb.ftp", qos: .utility)

    private var control: NWConnection?
    private var readBuffer = Data()

    init(configuration: Configuration) {
        self.configuration = configuration
    }

    // MARK: - Connection Lifecycle

    /// Open the control connection and log in.
    func connect() async throws {
        let connection = makeConnection(
            host: configuration.host,
            port: configuration.port,
            useTLS: configuration.useTLS
        )
        control = connection
        readBuffer = Data()

        try await waitUntilReady(connection)

        // Greeting
        let greeting = try await readResponse(on: connection)
        guard greeting.code == 220 else {
            throw FTPClientError.connectionFailed(greeting.message)
        }

        // Credentials
        let userReply = try await command("USER \(configuration.username)")
        if userReply.code == 331 {
            let passReply = try await command("PASS \(configuration.password)")
            guard passReply.code == 230 else {
                throw FTPClientError.authenticationFailed(passReply.message)
            }
        } else if userReply.code != 230 {
            throw FTPClientError.authenticationFailed(userReply.message)
        }

        // Binary transfers — HTML and images alike must not be line-ending mangled.
        _ = try await command("TYPE I")

        Logger.shared.info("FTP connected to \(configuration.host):\(configuration.port)", category: .general)
    }

    /// Close politely.
    func disconnect() async {
        if control != nil {
            _ = try? await command("QUIT")
        }
        control?.cancel()
        control = nil
        readBuffer = Data()
    }

    // MARK: - Operations

    /// Log in, then immediately log out. Used by "Test Connection".
    static func verify(configuration: Configuration) async throws -> String {
        let client = FTPClient(configuration: configuration)
        try await client.connect()

        // Prove we can actually reach the publish directory, not just log in.
        let path = configuration.remotePath.isEmpty ? "/" : configuration.remotePath
        let reply = try await client.command("CWD \(path)")
        await client.disconnect()

        guard reply.isPositive else {
            throw FTPClientError.unexpectedResponse(code: reply.code, message: "\(path) — \(reply.message)")
        }

        return "Connected to \(configuration.host) and opened \(path)."
    }

    /// Upload the contents of a local directory, recreating its structure remotely.
    /// - Parameter progress: called on each file with (completed, total).
    func uploadDirectory(
        _ localURL: URL,
        progress: (@Sendable (Int, Int) -> Void)? = nil
    ) async throws {
        guard control != nil else { throw FTPClientError.notConnected }

        let files = try Self.enumerateFiles(in: localURL)
        guard !files.isEmpty else {
            throw FTPClientError.transferFailed("Nothing to upload — the export directory is empty.")
        }

        let root = configuration.remotePath.isEmpty ? "" : configuration.remotePath
        try await ensureDirectory(root)

        var completed = 0
        for file in files {
            let relativePath = file.path.replacingOccurrences(of: localURL.path + "/", with: "")
            let remotePath = root.isEmpty ? relativePath : "\(root)/\(relativePath)"

            // Recreate intermediate directories.
            let remoteDirectory = (remotePath as NSString).deletingLastPathComponent
            if !remoteDirectory.isEmpty, remoteDirectory != root {
                try await ensureDirectory(remoteDirectory)
            }

            let data = try Data(contentsOf: file)
            try await store(data, at: remotePath)

            completed += 1
            progress?(completed, files.count)
            Logger.shared.debug("FTP uploaded \(relativePath) (\(completed)/\(files.count))", category: .general)
        }

        Logger.shared.info("FTP uploaded \(completed) files to \(configuration.host)", category: .general)
    }

    /// List the names in a remote directory.
    func list(path: String) async throws -> [String] {
        let data = try await withDataConnection { dataConnection in
            let reply = try await self.command("NLST \(path)")
            guard reply.code == 125 || reply.code == 150 else {
                throw FTPClientError.transferFailed(reply.message)
            }
            return try await self.readUntilClosed(dataConnection)
        }

        let closing = try await readResponse(on: try requireControl())
        guard closing.isPositive else {
            throw FTPClientError.transferFailed(closing.message)
        }

        return String(decoding: data, as: UTF8.self)
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    // MARK: - Commands

    @discardableResult
    func command(_ text: String) async throws -> Response {
        let connection = try requireControl()
        let payload = Data((text + "\r\n").utf8)
        try await send(payload, on: connection)
        return try await readResponse(on: connection)
    }

    /// Create a directory if it isn't already there. Existing directories are not an error.
    private func ensureDirectory(_ path: String) async throws {
        guard !path.isEmpty, path != "/" else { return }

        // Walk the path so nested directories are created in order.
        var built = path.hasPrefix("/") ? "/" : ""
        for component in path.split(separator: "/") {
            built = built.hasSuffix("/") ? built + component : built + "/" + component
            // 550 here means "already exists", which is the normal case.
            _ = try? await command("MKD \(built)")
        }
    }

    /// Upload one file's bytes to an absolute remote path.
    private func store(_ data: Data, at remotePath: String) async throws {
        _ = try await withDataConnection { dataConnection in
            let reply = try await self.command("STOR \(remotePath)")
            guard reply.code == 125 || reply.code == 150 else {
                throw FTPClientError.transferFailed("\(remotePath) — \(reply.message)")
            }
            try await self.send(data, on: dataConnection)
            return Data()
        }

        let closing = try await readResponse(on: try requireControl())
        guard closing.isPositive else {
            throw FTPClientError.transferFailed("\(remotePath) — \(closing.message)")
        }
    }

    // MARK: - Data Channel

    /// Open a passive-mode data connection, run `body`, then tear it down.
    private func withDataConnection<T>(
        _ body: (NWConnection) async throws -> T
    ) async throws -> T {
        let reply = try await command("PASV")
        guard reply.code == 227 else {
            throw FTPClientError.passiveModeFailed(reply.message)
        }

        let endpoint = try Self.parsePassiveResponse(reply.message)
        let dataConnection = makeConnection(
            host: endpoint.host,
            port: endpoint.port,
            useTLS: configuration.useTLS
        )

        try await waitUntilReady(dataConnection)
        defer { dataConnection.cancel() }

        return try await body(dataConnection)
    }

    /// Parse `227 Entering Passive Mode (h1,h2,h3,h4,p1,p2)`.
    static func parsePassiveResponse(_ message: String) throws -> (host: String, port: Int) {
        guard let open = message.lastIndex(of: "("),
              let close = message.lastIndex(of: ")"),
              open < close else {
            throw FTPClientError.passiveModeFailed(message)
        }

        let numbers = message[message.index(after: open)..<close]
            .split(separator: ",")
            .compactMap { Int($0.trimmingCharacters(in: .whitespaces)) }

        guard numbers.count == 6 else {
            throw FTPClientError.passiveModeFailed(message)
        }

        let host = numbers[0...3].map(String.init).joined(separator: ".")
        let port = numbers[4] * 256 + numbers[5]
        return (host, port)
    }

    // MARK: - Networking Primitives

    private func requireControl() throws -> NWConnection {
        guard let control else { throw FTPClientError.notConnected }
        return control
    }

    private func makeConnection(host: String, port: Int, useTLS: Bool) -> NWConnection {
        let parameters: NWParameters = useTLS
            ? NWParameters(tls: NWProtocolTLS.Options(), tcp: NWProtocolTCP.Options())
            : NWParameters(tls: nil, tcp: NWProtocolTCP.Options())

        return NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: UInt16(clamping: port)),
            using: parameters
        )
    }

    private func waitUntilReady(_ connection: NWConnection) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let box = ContinuationBox(continuation)

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    box.resume(returning: ())
                case .failed(let error):
                    box.resume(throwing: FTPClientError.connectionFailed(error.localizedDescription))
                case .cancelled:
                    box.resume(throwing: FTPClientError.connectionClosed)
                case .waiting(let error):
                    // Unreachable host, refused port — surface rather than hang.
                    box.resume(throwing: FTPClientError.connectionFailed(error.localizedDescription))
                default:
                    break
                }
            }

            connection.start(queue: queue)
        }
    }

    private func send(_ data: Data, on connection: NWConnection) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let box = ContinuationBox(continuation)
            connection.send(content: data, completion: .contentProcessed { error in
                if let error {
                    box.resume(throwing: FTPClientError.transferFailed(error.localizedDescription))
                } else {
                    box.resume(returning: ())
                }
            })
        }
    }

    private func receiveChunk(on connection: NWConnection) async throws -> Data {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
            let box = ContinuationBox(continuation)
            connection.receive(minimumIncompleteLength: 1, maximumLength: 65_536) { data, _, isComplete, error in
                if let error {
                    box.resume(throwing: FTPClientError.transferFailed(error.localizedDescription))
                } else if let data, !data.isEmpty {
                    box.resume(returning: data)
                } else if isComplete {
                    box.resume(returning: Data())
                } else {
                    box.resume(returning: Data())
                }
            }
        }
    }

    /// Drain a data connection until the server closes it.
    private func readUntilClosed(_ connection: NWConnection) async throws -> Data {
        var accumulated = Data()
        while true {
            let chunk = try await receiveChunk(on: connection)
            if chunk.isEmpty { break }
            accumulated.append(chunk)
        }
        return accumulated
    }

    // MARK: - Response Parsing

    /// Read one complete FTP reply, handling multi-line replies (`123-` … `123 `).
    private func readResponse(on connection: NWConnection) async throws -> Response {
        var firstCode: Int?

        while true {
            if let line = takeLine() {
                guard line.count >= 4, let code = Int(line.prefix(3)) else { continue }

                let separator = line[line.index(line.startIndex, offsetBy: 3)]
                let message = String(line.dropFirst(4)).trimmingCharacters(in: .whitespaces)

                if separator == "-" {
                    // Start (or continuation) of a multi-line reply.
                    if firstCode == nil { firstCode = code }
                    continue
                }

                if let firstCode, firstCode != code {
                    // Continuation line inside a multi-line reply.
                    continue
                }

                return Response(code: code, message: message)
            }

            let chunk = try await receiveChunk(on: connection)
            guard !chunk.isEmpty else { throw FTPClientError.connectionClosed }
            readBuffer.append(chunk)
        }
    }

    /// Pull one CRLF-terminated line out of the buffer, if a whole one is present.
    private func takeLine() -> String? {
        guard let range = readBuffer.firstRange(of: Data("\r\n".utf8)) else { return nil }
        let lineData = readBuffer[readBuffer.startIndex..<range.lowerBound]
        readBuffer.removeSubrange(readBuffer.startIndex..<range.upperBound)
        return String(decoding: lineData, as: UTF8.self)
    }

    // MARK: - Local File Enumeration

    /// Every regular file under `directory`, depth-first, excluding hidden files.
    nonisolated static func enumerateFiles(in directory: URL) throws -> [URL] {
        let fileManager = FileManager.default
        var results: [URL] = []

        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        for url in contents.sorted(by: { $0.path < $1.path }) {
            let isDirectory = (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDirectory {
                results.append(contentsOf: try enumerateFiles(in: url))
            } else {
                results.append(url)
            }
        }

        return results
    }
}
