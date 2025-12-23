//
//  SettingsView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Settings view
struct SettingsView: View {
    @State private var viewModel = SettingsViewModel()
    @State private var showingAPIKeySheet = false
    @State private var showingClearDataConfirmation = false
    @State private var showingResetAppConfirmation = false
    @State private var showAbout = false
    @State private var showingFilteredItems = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        NavigationStack {
            Form {
                // TMDb Section
                Section("TMDb Configuration") {
                    HStack {
                        Text("API Key")
                        Spacer()
                        Text(viewModel.apiKeyStatusText)
                            .foregroundStyle(viewModel.hasAPIKey ? .green : .red)
                        Button {
                            showingAPIKeySheet = true
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }

                    if viewModel.hasAPIKey {
                        HStack(spacing: 4) {
                            Button("Sync from TMDb") {
                                Task {
                                    await viewModel.syncFromTMDb()
                                }
                            }
                            .disabled(viewModel.isSyncing)

                            Text("to retrieve additional details")
                                .font(.body.pointSize(14))
                                .foregroundStyle(Color.primaryText)
                        }

                        if viewModel.isSyncing {
                            ProgressView(value: viewModel.syncProgress)
                        }

                        HStack {
                            Text("Last Sync")
                            Spacer()
                            Text(viewModel.lastSyncText)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Preferences
                Section("Preferences") {
                    Toggle("Haptic Feedback", isOn: $viewModel.hapticsEnabled)
                    Toggle("Notifications", isOn: $viewModel.notificationsEnabled)
                    Toggle("Achievement Notifications", isOn: $viewModel.achievementNotificationsEnabled)
                        .disabled(!viewModel.notificationsEnabled)
                }

                // Content Filtering
                Section {
                    Toggle("Hide Non-Acting Appearances", isOn: $viewModel.hideNonActingAppearances)
                    Toggle("Hide Documentaries", isOn: $viewModel.hideDocumentaries)

                    Button {
                        showingFilteredItems = true
                    } label: {
                        HStack {
                            Label("View Filtered Items", systemImage: "eye.slash.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(Color.tertiaryText)
                        }
                    }
                } header: {
                    Text("Content Filtering")
                } footer: {
                    Text("Filter out documentaries and appearances where Nicolas Cage is interviewed or featured as himself rather than acting in a role.")
                }

                // Cache
                Section("Cache") {
                    HStack {
                        Text("Cache Size")
                        Spacer()
                        Text(viewModel.cacheSize)
                            .foregroundStyle(.secondary)
                    }

                    Button("Clear Cache") {
                        Task {
                            await viewModel.clearCache()
                        }
                    }
                    .disabled(viewModel.isClearingCache)
                }

                // Data Management
                Section("Data Management") {
                    Button(role: .destructive) {
                        showingClearDataConfirmation = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash.fill")
                    }

                    Button(role: .destructive) {
                        showingResetAppConfirmation = true
                    } label: {
                        Label("Reset App Data", systemImage: "arrow.counterclockwise.circle.fill")
                    }
                }

                // Developer/Debug
                Section("Developer Tools") {
                    Button {
                        DataSeeder.shared.seedSampleMovies()
                    } label: {
                        Label("Seed Sample Data", systemImage: "leaf.fill")
                    }
                }
                .foregroundStyle(.blue)

                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(viewModel.fullVersionString)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    NCDBLogoView {
                        showAbout = true
                    }
                }
            }
            .sheet(isPresented: $showingAPIKeySheet, onDismiss: {
                // Refresh API key status when sheet is dismissed
                viewModel.refreshAPIKey()
            }) {
                APIKeySheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingFilteredItems) {
                FilteredItemsView()
            }
            .task {
                // Refresh API key status and time display when view appears
                viewModel.refreshAPIKey()
                viewModel.refreshTimeDisplay()
            }
            .confirmationDialog(
                "Clear All Data",
                isPresented: $showingClearDataConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All Data", role: .destructive) {
                    DataSeeder.shared.clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all movies, watch events, and achievements. This cannot be undone.")
            }
            .confirmationDialog(
                "Reset App Data",
                isPresented: $showingResetAppConfirmation,
                titleVisibility: .visible
            ) {
                Button("Reset Everything", role: .destructive) {
                    resetAppData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("⚠️ WARNING: This will completely reset the app to its first-launch state. All data, settings, API keys, and preferences will be permanently deleted. You will need to go through onboarding again. This cannot be undone.")
            }
        }
    }

    // MARK: - Reset App Data

    private func resetAppData() {
        Task {
            // Clear all database records
            DataSeeder.shared.clearAllData()

            // Clear image cache
            await ImageCacheManager.shared.clearAllCaches()

            // Clear Keychain (API keys)
            try? KeychainHelper.shared.delete(forKey: .tmdbAPIKey)
            try? KeychainHelper.shared.delete(forKey: .ftpPassword)

            // Clear UserDefaults
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }

            // Reset onboarding flag (this will trigger onboarding to show)
            hasCompletedOnboarding = false

            Logger.shared.info("App data reset complete", category: .general)
            HapticManager.shared.success()
        }
    }
}

struct APIKeySheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("TMDb API Key") {
                    TextField("API Key", text: $viewModel.apiKey)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if let result = viewModel.apiKeyValidationResult {
                        if result.isValid {
                            Label("Valid", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        } else if let error = result.errorMessage {
                            Label(error, systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }
                }

                Section {
                    Button("Save") {
                        Task {
                            await viewModel.saveAPIKey()
                            if viewModel.apiKeyValidationResult?.isValid == true {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isValidatingAPIKey || viewModel.apiKey.isEmpty)

                    if viewModel.hasAPIKey {
                        Button("Remove", role: .destructive) {
                            viewModel.removeAPIKey()
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}
