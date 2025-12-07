//
//  WebsiteExportView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SwiftData

/// Multi-step wizard for exporting user's collection as a website
struct WebsiteExportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Production.title) private var productions: [Production]

    @State private var currentStep = ExportStep.configure
    @State private var websiteTitle = ExportConfigurationManager.shared.websiteTitle
    @State private var userName = "My"
    @State private var includePosters = ExportConfigurationManager.shared.includePosters
    @State private var autoUpload = ExportConfigurationManager.shared.autoUpload

    @State private var isGenerating = false
    @State private var isUploading = false
    @State private var generatedWebsiteURL: URL?
    @State private var errorMessage: String?
    @State private var showingPreview = false
    @State private var showingFTPConfig = false

    private let exportService = WebsiteExportService.shared
    private let ftpService = FTPService.shared
    private let configManager = ExportConfigurationManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()

                VStack(spacing: Spacing.lg) {
                    // Progress Indicator
                    progressIndicator

                    // Current Step Content
                    ScrollView {
                        VStack(spacing: Spacing.xl) {
                            switch currentStep {
                            case .configure:
                                configurationStep
                            case .generate:
                                generationStep
                            case .upload:
                                uploadStep
                            case .complete:
                                completionStep
                            }
                        }
                        .padding()
                    }

                    // Navigation Buttons
                    navigationButtons
                }
            }
            .navigationTitle("Export Website")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPreview) {
                if let websiteURL = generatedWebsiteURL {
                    ExportPreviewView(websiteURL: websiteURL)
                }
            }
            .sheet(isPresented: $showingFTPConfig) {
                FTPConfigView()
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: Spacing.md) {
            ForEach(ExportStep.allCases, id: \.self) { step in
                VStack(spacing: Spacing.xs) {
                    Circle()
                        .fill(stepColor(for: step))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if step.rawValue < currentStep.rawValue {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.black)
                                    .font(.system(size: 14, weight: .bold))
                            } else {
                                Text("\(step.rawValue + 1)")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(step == currentStep ? Color.black : Color.secondaryText)
                            }
                        }

                    Text(step.title)
                        .font(.caption2)
                        .foregroundStyle(step == currentStep ? Color.cageGold : Color.secondaryText)
                }

                if step != ExportStep.allCases.last {
                    Rectangle()
                        .fill(step.rawValue < currentStep.rawValue ? Color.cageGold : Color.secondaryText.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
    }

    private func stepColor(for step: ExportStep) -> Color {
        if step.rawValue < currentStep.rawValue {
            return Color.cageGold
        } else if step == currentStep {
            return Color.cageGold
        } else {
            return Color.secondaryText.opacity(0.3)
        }
    }

    // MARK: - Step 1: Configuration

    private var configurationStep: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Configure Your Website")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.cageGold)

            Text("Customize how your collection will be displayed")
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)

            VStack(spacing: Spacing.md) {
                // Website Title
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Website Title")
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)

                    GlassTextField(
                        placeholder: "My Nicolas Cage Collection",
                        text: $websiteTitle
                    )
                }

                // User Name
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Your Name")
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)

                    GlassTextField(
                        placeholder: "Your name",
                        text: $userName
                    )
                }

                // Include Posters Toggle
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Include Poster Images")
                                .font(.headline)
                                .foregroundStyle(Color.primaryText)

                            Text("Download and include movie posters (increases file size)")
                                .font(.caption)
                                .foregroundStyle(Color.secondaryText)
                        }

                        Spacer()

                        Toggle("", isOn: $includePosters)
                            .tint(Color.cageGold)
                    }
                    .padding()
                }

                // Auto Upload Toggle
                GlassCard {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xxs) {
                            Text("Auto Upload via FTP")
                                .font(.headline)
                                .foregroundStyle(Color.primaryText)

                            Text(configManager.isFTPConfigured ? "Upload automatically after generation" : "Configure FTP first")
                                .font(.caption)
                                .foregroundStyle(Color.secondaryText)
                        }

                        Spacer()

                        Toggle("", isOn: $autoUpload)
                            .tint(Color.cageGold)
                            .disabled(!configManager.isFTPConfigured)
                    }
                    .padding()
                }

                // FTP Config Button
                if !configManager.isFTPConfigured {
                    GlassButton(title: "Configure FTP Settings", style: .secondary) {
                        showingFTPConfig = true
                    }
                }
            }

            // Stats Preview
            GlassCard {
                VStack(spacing: Spacing.sm) {
                    Text("Your Website Will Include")
                        .font(.headline)
                        .foregroundStyle(Color.cageGold)

                    HStack(spacing: Spacing.xl) {
                        statItem(
                            value: "\(productions.filter { $0.watched }.count)",
                            label: "Watched Movies"
                        )

                        statItem(
                            value: "\(productions.filter { ($0.rankingPosition ?? 0) > 0 }.count)",
                            label: "Ranked Movies"
                        )

                        statItem(
                            value: String(format: "%.0f%%", Double(productions.filter { $0.watched }.count) / max(Double(productions.count), 1.0) * 100),
                            label: "Completion"
                        )
                    }
                }
                .padding()
            }
        }
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: Spacing.xxs) {
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(Color.cageGold)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Step 2: Generation

    private var generationStep: some View {
        VStack(spacing: Spacing.lg) {
            if isGenerating {
                VStack(spacing: Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color.cageGold)

                    Text("Generating Your Website...")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primaryText)

                    Text("This may take a moment")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let websiteURL = generatedWebsiteURL {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.cageGold)

                    Text("Website Generated!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primaryText)

                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Location")
                                .font(.caption)
                                .foregroundStyle(Color.secondaryText)

                            Text(websiteURL.path)
                                .font(.caption)
                                .foregroundStyle(Color.primaryText)
                                .lineLimit(2)
                        }
                        .padding()
                    }

                    GlassButton(title: "Preview Website", style: .secondary) {
                        showingPreview = true
                    }
                }
            } else if let error = errorMessage {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.red)

                    Text("Generation Failed")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primaryText)

                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center)

                    GlassButton(title: "Try Again", style: .secondary) {
                        Task { await generateWebsite() }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if generatedWebsiteURL == nil && errorMessage == nil {
                await generateWebsite()
            }
        }
    }

    // MARK: - Step 3: Upload

    private var uploadStep: some View {
        VStack(spacing: Spacing.lg) {
            if !configManager.isFTPConfigured {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "network.slash")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.secondaryText)

                    Text("FTP Not Configured")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primaryText)

                    Text("Configure your FTP settings to upload your website")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                        .multilineTextAlignment(.center)

                    GlassButton(title: "Configure FTP", style: .primary) {
                        showingFTPConfig = true
                    }

                    GlassButton(title: "Skip Upload", style: .secondary) {
                        currentStep = .complete
                    }
                }
            } else if isUploading {
                VStack(spacing: Spacing.md) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(Color.cageGold)

                    Text("Uploading Website...")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.primaryText)

                    Text("Uploading to \(configManager.ftpHost)")
                        .font(.subheadline)
                        .foregroundStyle(Color.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: Spacing.lg) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(Color.cageGold)

                    Text("Upload Complete!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primaryText)

                    GlassCard {
                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            Text("Your website is now live at:")
                                .font(.caption)
                                .foregroundStyle(Color.secondaryText)

                            Text("\(configManager.ftpHost)\(configManager.ftpPath)")
                                .font(.subheadline)
                                .foregroundStyle(Color.cageGold)
                        }
                        .padding()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            if configManager.isFTPConfigured && autoUpload && generatedWebsiteURL != nil {
                await uploadWebsite()
            }
        }
    }

    // MARK: - Step 4: Complete

    private var completionStep: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "party.popper.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.cageGold)

            Text("All Done!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(Color.primaryText)

            Text("Your Nicolas Cage collection website is ready")
                .font(.title3)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)

            VStack(spacing: Spacing.sm) {
                if let websiteURL = generatedWebsiteURL {
                    GlassButton(title: "Preview Website", style: .primary) {
                        showingPreview = true
                    }

                    GlassButton(title: "Share Files", style: .secondary) {
                        shareWebsite(websiteURL)
                    }
                }

                if configManager.isFTPConfigured {
                    GlassButton(title: "View Live Site", style: .secondary) {
                        if let url = URL(string: "http://\(configManager.ftpHost)\(configManager.ftpPath)") {
                            UIApplication.shared.open(url)
                        }
                    }
                }
            }

            GlassButton(title: "Done", style: .primary) {
                saveConfiguration()
                dismiss()
            }
        }
        .padding()
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: Spacing.md) {
            if currentStep != .configure && currentStep != .complete {
                GlassButton(title: "Back", style: .secondary) {
                    withAnimation {
                        currentStep = ExportStep(rawValue: currentStep.rawValue - 1) ?? .configure
                    }
                }
            }

            if currentStep == .configure {
                GlassButton(title: "Generate Website", style: .primary) {
                    withAnimation {
                        currentStep = .generate
                    }
                }
            } else if currentStep == .generate && generatedWebsiteURL != nil {
                if configManager.isFTPConfigured && autoUpload {
                    GlassButton(title: "Upload", style: .primary) {
                        withAnimation {
                            currentStep = .upload
                        }
                    }
                } else {
                    GlassButton(title: "Complete", style: .primary) {
                        withAnimation {
                            currentStep = .complete
                        }
                    }
                }
            } else if currentStep == .upload && !isUploading {
                GlassButton(title: "Finish", style: .primary) {
                    withAnimation {
                        currentStep = .complete
                    }
                }
            }
        }
        .padding()
    }

    // MARK: - Actions

    private func generateWebsite() async {
        isGenerating = true
        errorMessage = nil

        do {
            let websiteURL = try await exportService.generateWebsite(
                productions: productions,
                userName: userName,
                includeImages: includePosters
            )

            await MainActor.run {
                generatedWebsiteURL = websiteURL
                isGenerating = false

                // Trigger positive action for app review
                AppReviewPrompt.shared.requestReviewAfterPositiveAction(action: .completedFirstExport)
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }

    private func uploadWebsite() async {
        guard let websiteURL = generatedWebsiteURL else { return }

        isUploading = true

        do {
            try await ftpService.uploadWebsite(from: websiteURL)

            await MainActor.run {
                isUploading = false
            }
        } catch {
            await MainActor.run {
                isUploading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func shareWebsite(_ url: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            rootVC.present(activityVC, animated: true)
        }
    }

    private func saveConfiguration() {
        configManager.websiteTitle = websiteTitle
        configManager.includePosters = includePosters
        configManager.autoUpload = autoUpload
    }

    // MARK: - Export Step

    enum ExportStep: Int, CaseIterable {
        case configure = 0
        case generate = 1
        case upload = 2
        case complete = 3

        var title: String {
            switch self {
            case .configure: return "Configure"
            case .generate: return "Generate"
            case .upload: return "Upload"
            case .complete: return "Done"
            }
        }
    }
}

#Preview {
    WebsiteExportView()
        .modelContainer(for: Production.self, inMemory: true)
}
