//
//  FTPConfigView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Configuration view for FTP/SFTP upload settings
struct FTPConfigView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var ftpHost: String
    @State private var ftpPort: Int
    @State private var ftpUsername: String
    @State private var ftpPassword: String
    @State private var ftpPath: String
    @State private var useSFTP: Bool

    @State private var isTesting = false
    @State private var testResult: Result<String, FTPService.FTPError>?
    @State private var showingDeleteConfirmation = false

    private let configManager = ExportConfigurationManager.shared
    private let ftpService = FTPService.shared

    init() {
        _ftpHost = State(initialValue: ExportConfigurationManager.shared.ftpHost)
        _ftpPort = State(initialValue: ExportConfigurationManager.shared.ftpPort)
        _ftpUsername = State(initialValue: ExportConfigurationManager.shared.ftpUsername)
        _ftpPassword = State(initialValue: ExportConfigurationManager.shared.getFTPPassword() ?? "")
        _ftpPath = State(initialValue: ExportConfigurationManager.shared.ftpPath)
        _useSFTP = State(initialValue: ExportConfigurationManager.shared.useSFTP)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        // Header
                        headerSection

                        // FTP Configuration
                        configurationSection

                        // Test Connection
                        testSection

                        // Export History
                        historySection

                        // Danger Zone
                        if configManager.isFTPConfigured {
                            dangerZone
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("FTP Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveConfiguration()
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .confirmationDialog(
                "Delete FTP Configuration",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    configManager.resetConfiguration()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all FTP settings and export history. This cannot be undone.")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "network")
                .font(.system(size: 48))
                .foregroundStyle(Color.cageGold)

            Text("FTP/SFTP Configuration")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.primaryText)

            Text("Configure your FTP server to automatically upload your website")
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom)
    }

    // MARK: - Configuration Section

    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Server Settings")
                .font(.headline)
                .foregroundStyle(Color.cageGold)

            // Protocol Toggle
            GlassCard {
                HStack {
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Text("Use SFTP")
                            .font(.headline)
                            .foregroundStyle(Color.primaryText)

                        Text("Secure FTP over SSH (recommended)")
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)
                    }

                    Spacer()

                    Toggle("", isOn: $useSFTP)
                        .tint(Color.cageGold)
                }
                .padding()
            }

            // Host
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Host")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primaryText)

                GlassTextField(
                    placeholder: "ftp.example.com",
                    text: $ftpHost
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .keyboardType(.URL)
            }

            // Port
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Port")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primaryText)

                HStack {
                    TextField("", value: $ftpPort, format: .number)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium)
                                .fill(Color(hex: "1A1A1A"))
                                .opacity(0.5)
                        )
                        .foregroundStyle(Color.primaryText)
                        .keyboardType(.numberPad)

                    Button {
                        ftpPort = useSFTP ? 22 : 21
                    } label: {
                        Text("Default")
                            .font(.caption)
                            .foregroundStyle(Color.cageGold)
                    }
                }
            }

            Divider()
                .background(Color.secondaryText.opacity(0.3))

            // Credentials
            Text("Credentials")
                .font(.headline)
                .foregroundStyle(Color.cageGold)

            // Username
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Username")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primaryText)

                GlassTextField(
                    placeholder: "username",
                    text: $ftpUsername
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            }

            // Password
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primaryText)

                SecureField("", text: $ftpPassword)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium)
                            .fill(Color(hex: "1A1A1A"))
                            .opacity(0.5)
                    )
                    .foregroundStyle(Color.primaryText)

                Text("Stored securely in Keychain")
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)
            }

            Divider()
                .background(Color.secondaryText.opacity(0.3))

            // Path
            Text("Upload Path")
                .font(.headline)
                .foregroundStyle(Color.cageGold)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Remote Directory")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primaryText)

                GlassTextField(
                    placeholder: "/public_html",
                    text: $ftpPath
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

                Text("The directory where your website will be uploaded")
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)
            }
        }
    }

    // MARK: - Test Section

    private var testSection: some View {
        VStack(spacing: Spacing.md) {
            GlassButton(
                title: isTesting ? "Testing Connection..." : "Test Connection",
                style: .secondary
            ) {
                Task {
                    await testConnection()
                }
            }
            .disabled(!isValid || isTesting)

            if let result = testResult {
                GlassCard {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(result.isSuccess ? .green : .red)

                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text(result.isSuccess ? "Connection Successful" : "Connection Failed")
                                .font(.headline)
                                .foregroundStyle(Color.primaryText)

                            Text(result.message)
                                .font(.caption)
                                .foregroundStyle(Color.secondaryText)
                        }

                        Spacer()
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Export History")
                .font(.headline)
                .foregroundStyle(Color.cageGold)

            let history = configManager.getExportHistory()

            if history.isEmpty {
                GlassCard {
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundStyle(Color.secondaryText)

                        Text("No exports yet")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(Array(history.prefix(5).enumerated()), id: \.offset) { _, record in
                        exportRecordRow(record)
                    }
                }

                if history.count > 5 {
                    Text("\(history.count - 5) more exports")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                }
            }
        }
    }

    private func exportRecordRow(_ record: ExportConfigurationManager.ExportRecord) -> some View {
        GlassCard {
            HStack {
                Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(record.success ? .green : .red)

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(record.destination)
                        .font(.subheadline)
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(1)

                    Text("\(record.movieCount) movies • \(record.date.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Danger Zone

    private var dangerZone: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Danger Zone")
                .font(.headline)
                .foregroundStyle(.red)

            GlassButton(
                title: "Delete Configuration",
                style: .secondary
            ) {
                showingDeleteConfirmation = true
            }
            .tint(.red)
        }
    }

    // MARK: - Validation

    private var isValid: Bool {
        !ftpHost.isEmpty &&
        !ftpUsername.isEmpty &&
        !ftpPassword.isEmpty &&
        ftpPort > 0 &&
        ftpPort < 65536
    }

    // MARK: - Actions

    private func saveConfiguration() {
        configManager.ftpHost = ftpHost
        configManager.ftpPort = ftpPort
        configManager.ftpUsername = ftpUsername
        configManager.ftpPath = ftpPath
        configManager.useSFTP = useSFTP

        if !ftpPassword.isEmpty {
            configManager.saveFTPPassword(ftpPassword)
        }

        Logger.shared.info("FTP configuration saved", category: .general)
    }

    private func testConnection() async {
        isTesting = true
        testResult = nil

        // Save current values temporarily
        saveConfiguration()

        let result = await ftpService.testConnection()

        await MainActor.run {
            testResult = result
            isTesting = false
        }
    }
}

// MARK: - Result Extension

extension Result where Success == String, Failure == FTPService.FTPError {
    var isSuccess: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var message: String {
        switch self {
        case .success(let message):
            return message
        case .failure(let error):
            return error.localizedDescription
        }
    }
}

#Preview {
    FTPConfigView()
}
