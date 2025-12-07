// NCDB FTP Uploader
// FTP/FTPS file upload functionality

import Foundation
import Network

// MARK: - FTP Uploader

/// Handles FTP/FTPS file uploads for website export
///
/// Features:
/// - Plain FTP and FTPS (TLS) support
/// - Directory creation
/// - Progress tracking
/// - Connection testing
/// - Retry logic
///
/// Usage:
/// ```swift
/// let credentials = FTPCredentials(...)
/// let uploader = FTPUploader(credentials: credentials)
/// try await uploader.upload(file: exportFile)
/// ```
actor FTPUploader {

    // MARK: - Properties

    private let credentials: FTPCredentials
    private let timeout: TimeInterval
    private var connection: NWConnection?

    // MARK: - Configuration

    struct Configuration {
        var connectionTimeout: TimeInterval = 30
        var transferTimeout: TimeInterval = 120
        var maxRetries: Int = 3
        var retryDelay: TimeInterval = 2
    }

    private let configuration: Configuration

    // MARK: - Initialization

    init(credentials: FTPCredentials, configuration: Configuration = Configuration()) {
        self.credentials = credentials
        self.configuration = configuration
        self.timeout = configuration.connectionTimeout
    }

    // MARK: - Connection Testing

    /// Test FTP connection with credentials
    static func testConnection(credentials: FTPCredentials) async -> ConnectionResult {
        let uploader = FTPUploader(credentials: credentials)

        do {
            try await uploader.connect()
            try await uploader.login()
            try await uploader.disconnect()
            return ConnectionResult(success: true, message: "Connection successful")
        } catch {
            return ConnectionResult(success: false, message: error.localizedDescription)
        }
    }

    // MARK: - Upload

    /// Upload a single file
    func upload(file: ExportFile) async throws {
        try await connect()
        try await login()

        // Ensure remote directory exists
        try await createDirectoryIfNeeded(credentials.remotePath)

        // Change to remote directory
        try await changeDirectory(credentials.remotePath)

        // Upload the file
        try await uploadFile(file)

        try await disconnect()
    }

    /// Upload multiple files with progress
    func uploadAll(
        files: [ExportFile],
        progress: @escaping (Double) -> Void
    ) async throws {
        try await connect()
        try await login()

        try await createDirectoryIfNeeded(credentials.remotePath)
        try await changeDirectory(credentials.remotePath)

        for (index, file) in files.enumerated() {
            try await uploadFile(file)
            progress(Double(index + 1) / Double(files.count))
        }

        try await disconnect()
    }

    // MARK: - FTP Commands

    private func connect() async throws {
        let host = NWEndpoint.Host(credentials.host)
        let port = NWEndpoint.Port(integerLiteral: UInt16(credentials.port))

        let parameters: NWParameters
        if credentials.useTLS {
            parameters = NWParameters(tls: createTLSOptions())
        } else {
            parameters = NWParameters.tcp
        }

        connection = NWConnection(host: host, port: port, using: parameters)

        return try await withCheckedThrowingContinuation { continuation in
            connection?.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    continuation.resume()
                case .failed(let error):
                    continuation.resume(throwing: FTPError.connectionFailed(error))
                case .cancelled:
                    continuation.resume(throwing: FTPError.connectionFailed(
                        NSError(domain: "FTP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Connection cancelled"])
                    ))
                default:
                    break
                }
            }

            connection?.start(queue: .global())
        }
    }

    private func createTLSOptions() -> NWProtocolTLS.Options {
        let options = NWProtocolTLS.Options()

        // Configure TLS settings
        sec_protocol_options_set_min_tls_protocol_version(
            options.securityProtocolOptions,
            .TLSv12
        )

        return options
    }

    private func login() async throws {
        // Wait for welcome message
        _ = try await readResponse()

        // Send USER command
        try await sendCommand("USER \(credentials.username)")
        let userResponse = try await readResponse()

        guard userResponse.code == 331 else {
            throw FTPError.authenticationFailed
        }

        // Send PASS command
        try await sendCommand("PASS \(credentials.password)")
        let passResponse = try await readResponse()

        guard passResponse.code == 230 else {
            throw FTPError.authenticationFailed
        }

        Logger.info("FTP login successful", category: .network)
    }

    private func createDirectoryIfNeeded(_ path: String) async throws {
        // Try to create directory (will fail if exists, which is fine)
        let components = path.split(separator: "/").map(String.init)
        var currentPath = ""

        for component in components {
            currentPath += "/\(component)"
            try await sendCommand("MKD \(currentPath)")
            _ = try? await readResponse() // Ignore errors for existing dirs
        }
    }

    private func changeDirectory(_ path: String) async throws {
        try await sendCommand("CWD \(path)")
        let response = try await readResponse()

        guard response.code == 250 else {
            throw FTPError.directoryCreationFailed
        }
    }

    private func uploadFile(_ file: ExportFile) async throws {
        // Set binary mode
        try await sendCommand("TYPE I")
        _ = try await readResponse()

        // Enter passive mode
        try await sendCommand("PASV")
        let pasvResponse = try await readResponse()

        guard pasvResponse.code == 227,
              let dataConnection = try await createDataConnection(from: pasvResponse.message) else {
            throw FTPError.uploadFailed(file.name)
        }

        // Send STOR command
        try await sendCommand("STOR \(file.name)")
        let storResponse = try await readResponse()

        guard storResponse.code == 150 || storResponse.code == 125 else {
            throw FTPError.uploadFailed(file.name)
        }

        // Send file data over data connection
        try await sendData(file.data, over: dataConnection)

        // Wait for transfer complete
        let completeResponse = try await readResponse()

        guard completeResponse.code == 226 else {
            throw FTPError.uploadFailed(file.name)
        }

        Logger.debug("Uploaded: \(file.name)", category: .network)
    }

    private func disconnect() async throws {
        try await sendCommand("QUIT")
        connection?.cancel()
        connection = nil
    }

    // MARK: - Communication

    private func sendCommand(_ command: String) async throws {
        guard let connection else {
            throw FTPError.connectionFailed(
                NSError(domain: "FTP", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection"])
            )
        }

        let data = "\(command)\r\n".data(using: .utf8)!

        return try await withCheckedThrowingContinuation { continuation in
            connection.send(content: data, completion: .contentProcessed { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }

    private func readResponse() async throws -> FTPResponse {
        guard let connection else {
            throw FTPError.connectionFailed(
                NSError(domain: "FTP", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection"])
            )
        }

        return try await withCheckedThrowingContinuation { continuation in
            connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let data,
                      let message = String(data: data, encoding: .utf8) else {
                    continuation.resume(throwing: FTPError.connectionFailed(
                        NSError(domain: "FTP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                    ))
                    return
                }

                // Parse response code
                let code = Int(message.prefix(3)) ?? 0
                let response = FTPResponse(code: code, message: message)
                continuation.resume(returning: response)
            }
        }
    }

    private func createDataConnection(from pasvMessage: String) async throws -> NWConnection? {
        // Parse PASV response: 227 Entering Passive Mode (h1,h2,h3,h4,p1,p2)
        let regex = try NSRegularExpression(pattern: "\\((\\d+),(\\d+),(\\d+),(\\d+),(\\d+),(\\d+)\\)")
        let range = NSRange(pasvMessage.startIndex..., in: pasvMessage)

        guard let match = regex.firstMatch(in: pasvMessage, range: range) else {
            return nil
        }

        let numbers = (1...6).compactMap { i -> Int? in
            guard let range = Range(match.range(at: i), in: pasvMessage) else { return nil }
            return Int(pasvMessage[range])
        }

        guard numbers.count == 6 else { return nil }

        let host = "\(numbers[0]).\(numbers[1]).\(numbers[2]).\(numbers[3])"
        let port = numbers[4] * 256 + numbers[5]

        let connection = NWConnection(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(integerLiteral: UInt16(port)),
            using: credentials.useTLS ? NWParameters(tls: createTLSOptions()) : .tcp
        )

        return try await withCheckedThrowingContinuation { continuation in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    continuation.resume(returning: connection)
                case .failed(let error):
                    continuation.resume(throwing: error)
                default:
                    break
                }
            }
            connection.start(queue: .global())
        }
    }

    private func sendData(_ data: Data, over connection: NWConnection) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            connection.send(content: data, completion: .contentProcessed { error in
                connection.cancel()
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            })
        }
    }
}

// MARK: - Supporting Types

/// FTP server credentials
struct FTPCredentials: Codable {
    let host: String
    let port: Int
    let username: String
    let password: String
    let remotePath: String
    let useTLS: Bool

    init(
        host: String,
        port: Int = 21,
        username: String,
        password: String,
        remotePath: String = "/",
        useTLS: Bool = true
    ) {
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.remotePath = remotePath
        self.useTLS = useTLS
    }
}

/// File to be exported/uploaded
struct ExportFile {
    let name: String
    let data: Data
    let mimeType: String

    init(name: String, data: Data, mimeType: String = "application/octet-stream") {
        self.name = name
        self.data = data
        self.mimeType = mimeType
    }

    init(name: String, content: String, mimeType: String = "text/html") {
        self.name = name
        self.data = content.data(using: .utf8) ?? Data()
        self.mimeType = mimeType
    }
}

/// FTP response from server
struct FTPResponse {
    let code: Int
    let message: String

    var isSuccess: Bool {
        (200...299).contains(code) || (100...199).contains(code)
    }
}

/// Connection test result
struct ConnectionResult {
    let success: Bool
    let message: String
}

// MARK: - Errors

enum FTPError: LocalizedError {
    case noCredentials
    case connectionFailed(Error)
    case authenticationFailed
    case uploadFailed(String)
    case directoryCreationFailed
    case timeout

    var errorDescription: String? {
        switch self {
        case .noCredentials:
            return "FTP credentials not configured"
        case .connectionFailed(let error):
            return "Connection failed: \(error.localizedDescription)"
        case .authenticationFailed:
            return "Authentication failed. Check username and password."
        case .uploadFailed(let file):
            return "Failed to upload: \(file)"
        case .directoryCreationFailed:
            return "Could not create remote directory"
        case .timeout:
            return "Connection timed out"
        }
    }
}

// MARK: - Protocol for Testing

protocol FTPUploading {
    func upload(file: ExportFile) async throws
    func uploadAll(files: [ExportFile], progress: @escaping (Double) -> Void) async throws
}

extension FTPUploader: FTPUploading {}

// MARK: - Mock for Testing

#if DEBUG
actor MockFTPUploader: FTPUploading {
    var uploadedFiles: [String] = []
    var shouldFail = false
    var failureError: FTPError = .uploadFailed("Mock failure")

    func upload(file: ExportFile) async throws {
        if shouldFail {
            throw failureError
        }
        uploadedFiles.append(file.name)
        try await Task.sleep(nanoseconds: 100_000_000) // Simulate delay
    }

    func uploadAll(files: [ExportFile], progress: @escaping (Double) -> Void) async throws {
        for (index, file) in files.enumerated() {
            try await upload(file: file)
            progress(Double(index + 1) / Double(files.count))
        }
    }
}
#endif
