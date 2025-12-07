//
//  TMDbSetupView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// TMDb API key setup screen
struct TMDbSetupView: View {
    @Binding var apiKey: String
    let onContinue: () -> Void

    @State private var isValidating = false
    @State private var validationResult: ValidationResult?
    @State private var showingInfo = false

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.xl) {
                // Header
                VStack(spacing: Spacing.sm) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.cageGold)

                    Text("TMDb API Setup")
                        .font(.title.bold())
                        .foregroundStyle(Color.primaryText)

                    Text("We need a TMDb API key to fetch movie data")
                        .font(.body)
                        .foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Spacing.xxl)

                // API Key input
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    HStack {
                        Text("API Key")
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.primaryText)

                        Spacer()

                        Button {
                            showingInfo = true
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.cageGold)
                        }
                    }

                    GlassTextField(
                        placeholder: "Enter your TMDb API key",
                        text: $apiKey
                    )

                    if let result = validationResult {
                        if result.isValid {
                            Label("Valid API key", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else if let errorMessage = result.errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.horizontal, Spacing.xl)

                // Buttons
                VStack(spacing: Spacing.md) {
                    GlassButton(
                        title: isValidating ? "Validating..." : "Validate & Continue",
                        style: .primary
                    ) {
                        Task {
                            await validateAndContinue()
                        }
                    }
                    .disabled(apiKey.isEmpty || isValidating)

                    Button("Skip for Now") {
                        HapticManager.shared.buttonTap()
                        onContinue()
                    }
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
                }
                .padding(.horizontal, Spacing.xl)

                Spacer()
            }
        }
        .sheet(isPresented: $showingInfo) {
            TMDbInfoSheet()
        }
    }

    private func validateAndContinue() async {
        isValidating = true

        let result = await ValidationHelper.validateTMDbAPIKey(apiKey)
        validationResult = result

        if result.isValid {
            // Save to keychain
            do {
                try KeychainHelper.shared.saveTMDbAPIKey(apiKey)
                HapticManager.shared.success()

                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
                onContinue()
            } catch {
                validationResult = .invalid("Failed to save API key: \(error.localizedDescription)")
                HapticManager.shared.error()
                Logger.shared.error("Failed to save TMDb API key: \(error)", category: .general)
            }
        } else {
            HapticManager.shared.error()
        }

        isValidating = false
    }
}

struct TMDbInfoSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text("How to Get a TMDb API Key")
                        .font(.title2.bold())

                    VStack(alignment: .leading, spacing: Spacing.md) {
                        StepView(number: 1, text: "Visit themoviedb.org and create a free account")
                        StepView(number: 2, text: "Go to Settings > API")
                        StepView(number: 3, text: "Request an API key (choose 'Developer')")
                        StepView(number: 4, text: "Copy your API key and paste it here")
                    }

                    Text("Why do we need this?")
                        .font(.headline)
                        .padding(.top, Spacing.md)

                    Text("The TMDb API key allows NCDB to fetch movie information, posters, and metadata for Nicolas Cage's filmography. Your key is stored securely in your device's keychain and is never shared.")
                        .font(.body)
                        .foregroundStyle(Color.secondaryText)
                }
                .padding(Spacing.lg)
            }
            .background(Color.primaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct StepView: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text("\(number)")
                .font(.headline)
                .foregroundStyle(.cageGold)
                .frame(width: 24, height: 24)
                .background(Color.cageGold.opacity(0.2))
                .clipShape(Circle())

            Text(text)
                .font(.body)
                .foregroundStyle(Color.primaryText)
        }
    }
}
