//
//  FTPService.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation

/// Uploads an exported website to an FTP or FTPS server.
///
/// Backed by `FTPClient`, a real Network.framework implementation. Every method
/// here reaches the network — nothing is simulated, and a failure is reported
/// as a failure.
@MainActor
final class FTPService {
    static let shared = FTPService()

    private let config = ExportConfigurationManager.shared

    private init() {}

    // MARK: - Progress

    /// Files uploaded so far, and the total, while an upload is running.
    private(set) var uploadProgress: (completed: Int, total: Int)?

    // MARK: - Configuration

    private func makeClientConfiguration() throws -> FTPClient.Configuration {
        let validation = config.validateFTPConfig()
        guard validation.isValid else {
            throw FTPError.invalidConfiguration(validation.errorMessage ?? "Invalid configuration")
        }

        guard let password = config.getFTPPassword(), !password.isEmpty else {
            throw FTPError.invalidConfiguration("No password saved for this server.")
        }

        return FTPClient.Configuration(
            host: config.ftpHost,
            port: config.ftpPort,
            username: config.ftpUsername,
            password: password,
            useTLS: config.useFTPS,
            remotePath: config.ftpPath
        )
    }

    // MARK: - Upload

    /// Upload an exported website directory to the configured server.
    func uploadWebsite(from localURL: URL) async throws {
        Logger.shared.info("Starting FTP upload to \(config.ftpHost)...", category: .general)

        let clientConfiguration = try makeClientConfiguration()
        let client = FTPClient(configuration: clientConfiguration)

        uploadProgress = (0, 0)
        defer { uploadProgress = nil }

        do {
            try await client.connect()
        } catch {
            config.recordExport(movieCount: 0, success: false, destination: "\(config.ftpHost)\(config.ftpPath)")
            throw FTPError.connectionFailed(error.localizedDescription)
        }

        do {
            let fileCount = try FTPClient.enumerateFiles(in: localURL).count
            uploadProgress = (0, fileCount)

            // The callback fires from the FTP actor, so hop back explicitly.
            try await client.uploadDirectory(localURL) { completed, total in
                Task { @MainActor in
                    FTPService.shared.uploadProgress = (completed, total)
                }
            }

            await client.disconnect()

            Logger.shared.info("FTP upload completed: \(fileCount) files", category: .general)

            config.recordExport(
                movieCount: fileCount,
                success: true,
                destination: "\(config.ftpHost)\(config.ftpPath)"
            )
        } catch {
            await client.disconnect()
            config.recordExport(movieCount: 0, success: false, destination: "\(config.ftpHost)\(config.ftpPath)")
            throw FTPError.uploadFailed(error.localizedDescription)
        }
    }

    // MARK: - Connection Testing

    /// Test the configured server by logging in and opening the publish directory.
    func testConnection() async -> Result<String, FTPError> {
        Logger.shared.info("Testing FTP connection to \(config.ftpHost)...", category: .general)

        do {
            let clientConfiguration = try makeClientConfiguration()
            let message = try await FTPClient.verify(configuration: clientConfiguration)
            Logger.shared.info(message, category: .general)
            return .success(message)
        } catch let error as FTPError {
            Logger.shared.error("FTP test failed: \(error.localizedDescription)", category: .general)
            return .failure(error)
        } catch {
            Logger.shared.error("FTP test failed: \(error.localizedDescription)", category: .general)
            return .failure(.connectionFailed(error.localizedDescription))
        }
    }

    // MARK: - File Operations

    /// List files in a remote directory.
    func listRemoteFiles(path: String? = nil) async throws -> [RemoteFile] {
        let targetPath = path ?? config.ftpPath
        let clientConfiguration = try makeClientConfiguration()
        let client = FTPClient(configuration: clientConfiguration)

        try await client.connect()
        defer { Task { await client.disconnect() } }

        let names = try await client.list(path: targetPath.isEmpty ? "/" : targetPath)

        return names.map { name in
            RemoteFile(
                name: (name as NSString).lastPathComponent,
                size: 0,
                modifiedDate: nil,
                isDirectory: !(name as NSString).lastPathComponent.contains(".")
            )
        }
    }

    /// Delete a file from the remote server.
    func deleteRemoteFile(_ filename: String, at path: String? = nil) async throws {
        let targetPath = path ?? config.ftpPath
        let remotePath = targetPath.isEmpty ? filename : "\(targetPath)/\(filename)"

        let clientConfiguration = try makeClientConfiguration()
        let client = FTPClient(configuration: clientConfiguration)

        try await client.connect()
        defer { Task { await client.disconnect() } }

        let reply = try await client.command("DELE \(remotePath)")
        guard reply.isPositive else {
            throw FTPError.uploadFailed("Couldn't delete \(filename): \(reply.message)")
        }

        Logger.shared.info("Deleted \(remotePath)", category: .general)
    }

    // MARK: - Supporting Types

    struct RemoteFile {
        let name: String
        let size: Int64
        let modifiedDate: Date?
        let isDirectory: Bool
    }

    enum FTPError: LocalizedError {
        case invalidConfiguration(String)
        case connectionFailed(String)
        case authenticationFailed
        case uploadFailed(String)
        case downloadFailed(String)
        case fileNotFound

        var errorDescription: String? {
            switch self {
            case .invalidConfiguration(let message):
                return "Configuration Error: \(message)"
            case .connectionFailed(let message):
                return "Connection Failed: \(message)"
            case .authenticationFailed:
                return "Authentication failed. Please check your credentials."
            case .uploadFailed(let message):
                return "Upload Failed: \(message)"
            case .downloadFailed(let message):
                return "Download Failed: \(message)"
            case .fileNotFound:
                return "File not found on remote server"
            }
        }
    }
}
