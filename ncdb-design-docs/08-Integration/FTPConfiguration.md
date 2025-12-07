# FTP Configuration Guide

## Overview

The NCDB project includes optional FTP functionality for exporting user data and static website content to a web server. This enables users to host their personal Nicolas Cage movie rankings and statistics online.

## Use Cases

1. **Personal Website Export** - Generate and upload a static HTML site
2. **Data Backup** - Upload JSON exports to remote storage
3. **Sharing** - Publish rankings to a custom domain

## Configuration

### FTP Credentials Storage

Credentials are stored securely in the Keychain:

```swift
struct FTPCredentials: Codable {
    let host: String
    let port: Int
    let username: String
    let password: String
    let remotePath: String
    let useTLS: Bool

    static let defaultPort = 21
    static let defaultTLSPort = 990
}

// Save credentials
func saveFTPCredentials(_ credentials: FTPCredentials) throws {
    let data = try JSONEncoder().encode(credentials)
    try KeychainHelper.shared.save(key: .ftpCredentials, data: data)
}

// Retrieve credentials
func getFTPCredentials() -> FTPCredentials? {
    guard let data = KeychainHelper.shared.read(key: .ftpCredentials) else {
        return nil
    }
    return try? JSONDecoder().decode(FTPCredentials.self, from: data)
}
```

### Keychain Key Extension

```swift
extension KeychainHelper.Key {
    static let ftpCredentials = KeychainHelper.Key("ncdb_ftp_credentials")
}
```

## Settings UI

### FTP Settings View

```swift
struct FTPSettingsView: View {
    @State private var host = ""
    @State private var port = "21"
    @State private var username = ""
    @State private var password = ""
    @State private var remotePath = "/public_html/ncdb"
    @State private var useTLS = true
    @State private var isTestingConnection = false
    @State private var connectionResult: ConnectionResult?

    var body: some View {
        Form {
            Section("Server") {
                TextField("Host", text: $host)
                    .textContentType(.URL)
                    .autocapitalization(.none)

                TextField("Port", text: $port)
                    .keyboardType(.numberPad)

                Toggle("Use TLS/SSL", isOn: $useTLS)
            }

            Section("Authentication") {
                TextField("Username", text: $username)
                    .textContentType(.username)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textContentType(.password)
            }

            Section("Remote Path") {
                TextField("Path", text: $remotePath)
                    .autocapitalization(.none)

                Text("Files will be uploaded to this directory")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Button {
                    testConnection()
                } label: {
                    HStack {
                        Text("Test Connection")
                        Spacer()
                        if isTestingConnection {
                            ProgressView()
                        } else if let result = connectionResult {
                            Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.success ? .green : .red)
                        }
                    }
                }
                .disabled(host.isEmpty || username.isEmpty)
            }

            Section {
                Button("Save Configuration") {
                    saveConfiguration()
                }
                .disabled(!isValid)
            }
        }
        .navigationTitle("FTP Settings")
        .onAppear(perform: loadExistingCredentials)
    }

    private var isValid: Bool {
        !host.isEmpty && !username.isEmpty && Int(port) != nil
    }

    private func testConnection() {
        isTestingConnection = true
        connectionResult = nil

        Task {
            let credentials = FTPCredentials(
                host: host,
                port: Int(port) ?? 21,
                username: username,
                password: password,
                remotePath: remotePath,
                useTLS: useTLS
            )

            let result = await FTPUploader.testConnection(credentials: credentials)

            await MainActor.run {
                isTestingConnection = false
                connectionResult = result
            }
        }
    }

    private func saveConfiguration() {
        let credentials = FTPCredentials(
            host: host,
            port: Int(port) ?? 21,
            username: username,
            password: password,
            remotePath: remotePath,
            useTLS: useTLS
        )

        try? saveFTPCredentials(credentials)
        HapticManager.shared.success()
    }

    private func loadExistingCredentials() {
        guard let credentials = getFTPCredentials() else { return }
        host = credentials.host
        port = String(credentials.port)
        username = credentials.username
        password = credentials.password
        remotePath = credentials.remotePath
        useTLS = credentials.useTLS
    }
}

struct ConnectionResult {
    let success: Bool
    let message: String
}
```

## Security Considerations

### Credential Storage

- **Always use Keychain** for storing FTP credentials
- Never store passwords in UserDefaults or plain files
- Consider using SFTP (SSH) instead of FTP when possible

### TLS/SSL

- Enable TLS by default for encrypted transfers
- Validate server certificates
- Support both explicit (FTPS) and implicit TLS

```swift
enum FTPSecurityMode {
    case none           // Plain FTP (insecure)
    case explicit       // FTPS - Start with FTP, upgrade to TLS
    case implicit       // FTPS - TLS from the start (port 990)
}
```

### Network Security

```swift
// Info.plist - Allow arbitrary loads for FTP (if needed)
// Prefer using App Transport Security exceptions for specific hosts

<key>NSAppTransportSecurity</key>
<dict>
    <key>NSExceptionDomains</key>
    <dict>
        <key>example.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <true/>
            <key>NSIncludesSubdomains</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## Upload Workflow

### Manual Export

```swift
struct ExportView: View {
    @State private var isExporting = false
    @State private var exportProgress: Double = 0

    var body: some View {
        VStack {
            Button("Export to Website") {
                exportToWebsite()
            }
            .disabled(isExporting)

            if isExporting {
                ProgressView(value: exportProgress)
                    .progressViewStyle(.linear)
            }
        }
    }

    private func exportToWebsite() {
        isExporting = true

        Task {
            do {
                // 1. Generate static site
                let generator = WebsiteGenerator()
                let files = try await generator.generateSite()

                // 2. Upload via FTP
                guard let credentials = getFTPCredentials() else {
                    throw FTPError.noCredentials
                }

                let uploader = FTPUploader(credentials: credentials)

                for (index, file) in files.enumerated() {
                    try await uploader.upload(file: file)
                    await MainActor.run {
                        exportProgress = Double(index + 1) / Double(files.count)
                    }
                }

                HapticManager.shared.success()
            } catch {
                ErrorHandler.shared.handle(error)
            }

            await MainActor.run {
                isExporting = false
            }
        }
    }
}
```

### Automatic Sync

```swift
// Optional: Auto-upload when rankings change
struct FTPSyncSettings {
    var autoUploadEnabled: Bool = false
    var uploadOnRankingChange: Bool = true
    var uploadOnNewWatch: Bool = false
    var uploadInterval: TimeInterval = 24 * 60 * 60 // Daily
}
```

## Error Handling

```swift
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
```

## Testing

### Local FTP Server

For development, use a local FTP server:

```bash
# macOS - Enable built-in FTP (deprecated but works)
sudo -s launchctl load -w /System/Library/LaunchDaemons/ftp.plist

# Or use Docker
docker run -d -p 21:21 -p 21000-21010:21000-21010 \
    -e USERS="test|test123" \
    delfer/alpine-ftp-server
```

### Mock Uploader

```swift
#if DEBUG
class MockFTPUploader: FTPUploading {
    var uploadedFiles: [String] = []
    var shouldFail = false

    func upload(file: ExportFile) async throws {
        if shouldFail {
            throw FTPError.uploadFailed(file.name)
        }
        uploadedFiles.append(file.name)
        // Simulate network delay
        try await Task.sleep(nanoseconds: 100_000_000)
    }
}
#endif
```

## Alternative: SFTP

Consider using SFTP (SSH File Transfer Protocol) for better security:

```swift
// Using a library like NMSSH or Shout
struct SFTPCredentials {
    let host: String
    let port: Int  // Default: 22
    let username: String
    let privateKeyPath: String?  // For key-based auth
    let password: String?
}
```

## Troubleshooting

### Common Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| Connection refused | Wrong port or firewall | Check port 21/990 is open |
| Auth failed | Wrong credentials | Verify username/password |
| Permission denied | User lacks write access | Check remote directory permissions |
| Timeout | Network issues | Increase timeout, check connectivity |
| TLS handshake failed | Certificate issue | Verify server certificate |

### Debug Logging

```swift
#if DEBUG
extension FTPUploader {
    func enableVerboseLogging() {
        // Log all FTP commands and responses
        Logger.configuration.minimumLevel = .debug
    }
}
#endif
```
