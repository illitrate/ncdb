// TMDbSetupView.swift
// NCDB - TMDb API Key Setup
// Critical setup screen for TMDb integration

import SwiftUI

struct TMDbSetupView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    @StateObject private var viewModel = TMDbSetupViewModel()
    @State private var apiKey = ""
    @State private var showingError = false
    @State private var isValidating = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // TMDb Logo
                    Image("TMDbLogo") // You'll need to add this asset
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .padding(.top, 60)
                    
                    // Title & Description
                    VStack(spacing: 12) {
                        Text("Connect to The Movie Database")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                        
                        Text("NCDB uses TMDb to fetch movie data, posters, and details. You'll need a free API key to continue.")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // API Key Input
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "key.fill")
                                .foregroundStyle(Color(hex: "FFD700"))
                            
                            TextField("Enter API Key", text: $apiKey)
                                .textFieldStyle(.plain)
                                .foregroundStyle(.white)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if showingError {
                            Text("Invalid API key. Please check and try again.")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Get API Key Link
                    Button {
                        if let url = URL(string: "https://www.themoviedb.org/settings/api") {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        HStack {
                            Text("Don't have a key?")
                                .foregroundStyle(.white.opacity(0.7))
                            Text("Get One Free")
                                .foregroundStyle(Color(hex: "FFD700"))
                        }
                        .font(.system(size: 15, weight: .medium))
                    }
                    
                    Spacer()
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await validateAndContinue()
                            }
                        } label: {
                            HStack {
                                if isValidating {
                                    ProgressView()
                                        .tint(.black)
                                }
                                Text(isValidating ? "Validating..." : "Continue")
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(apiKey.isEmpty ? Color.gray : Color(hex: "FFD700"))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .disabled(apiKey.isEmpty || isValidating)
                        
                        Button {
                            onSkip()
                        } label: {
                            Text("Skip for Now")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    func validateAndContinue() async {
        isValidating = true
        showingError = false
        
        do {
            let isValid = try await viewModel.validateAPIKey(apiKey)
            if isValid {
                viewModel.saveAPIKey(apiKey)
                onComplete()
            } else {
                showingError = true
            }
        } catch {
            showingError = true
        }
        
        isValidating = false
    }
}

@MainActor
class TMDbSetupViewModel: ObservableObject {
    func validateAPIKey(_ key: String) async throws -> Bool {
        // Test API key with a simple request
        let url = URL(string: "https://api.themoviedb.org/3/configuration?api_key=\(key)")!
        let (_, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            return false
        }
        
        return true
    }
    
    func saveAPIKey(_ key: String) {
        // Save to Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "TMDbAPIKey",
            kSecValueData as String: key.data(using: .utf8)!
        ]
        
        // Delete existing key if present
        SecItemDelete(query as CFDictionary)
        
        // Add new key
        SecItemAdd(query as CFDictionary, nil)
    }
}

#Preview {
    TMDbSetupView(onComplete: {}, onSkip: {})
}
