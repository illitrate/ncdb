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
                        Button("Sync from TMDb") {
                            Task {
                                await viewModel.syncFromTMDb()
                            }
                        }
                        .disabled(viewModel.isSyncing)

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
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAPIKeySheet) {
                APIKeySheet(viewModel: viewModel)
            }
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
