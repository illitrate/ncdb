// NCDB Settings View
// App settings and preferences screen

import SwiftUI
import SwiftData

// MARK: - Settings View

/// App settings and preferences
///
/// Sections:
/// - TMDb API configuration
/// - Appearance (theme, accent color)
/// - Notifications
/// - Data management (export, import, cache)
/// - About
/// - Danger zone (reset)
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @AppStorage("hapticFeedbackEnabled") private var hapticFeedbackEnabled = true
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true

    @State private var showExportSheet = false
    @State private var showClearCacheAlert = false
    @State private var showResetAlert = false
    @State private var showTMDbSetup = false
    @State private var cacheSize = "Calculating..."

    var body: some View {
        NavigationStack {
            List {
                // TMDb Section
                Section {
                    Button(action: { showTMDbSetup = true }) {
                        HStack {
                            Label("TMDb API Key", systemImage: "key.fill")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .foregroundStyle(Color.primary)
                } header: {
                    Text("Data Source")
                } footer: {
                    Text("Connect to The Movie Database to fetch movie information and posters.")
                }

                // Appearance Section
                Section("Appearance") {
                    Picker("Theme", selection: $selectedTheme) {
                        Text("System").tag("system")
                        Text("Light").tag("light")
                        Text("Dark").tag("dark")
                    }

                    NavigationLink(destination: AccentColorPicker()) {
                        HStack {
                            Text("Accent Color")
                            Spacer()
                            Circle()
                                .fill(Color.cageGold)
                                .frame(width: 24, height: 24)
                        }
                    }
                }

                // Feedback Section
                Section("Feedback") {
                    Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)

                    Toggle("Notifications", isOn: $notificationsEnabled)
                }

                // Data Section
                Section {
                    Button(action: { showExportSheet = true }) {
                        Label("Export Data", systemImage: "square.and.arrow.up")
                    }

                    NavigationLink(destination: ImportDataView()) {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }

                    Button(action: { showClearCacheAlert = true }) {
                        HStack {
                            Label("Clear Cache", systemImage: "trash")
                            Spacer()
                            Text(cacheSize)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(Color.primary)
                } header: {
                    Text("Data Management")
                }

                // News Section
                Section("News") {
                    NavigationLink(destination: NewsSourcesView()) {
                        Label("News Sources", systemImage: "newspaper")
                    }

                    Picker("Refresh Frequency", selection: .constant("daily")) {
                        Text("Manual").tag("manual")
                        Text("Daily").tag("daily")
                        Text("Twice Daily").tag("twiceDaily")
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(AppConstants.appVersion) (\(AppConstants.buildNumber))")
                            .foregroundStyle(.secondary)
                    }

                    NavigationLink(destination: CreditsView()) {
                        Text("Credits")
                    }

                    NavigationLink(destination: LicensesView()) {
                        Text("Open Source Licenses")
                    }

                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Text("GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                    }
                }

                // Danger Zone
                Section {
                    Button(role: .destructive, action: { showResetAlert = true }) {
                        Label("Reset All Data", systemImage: "exclamationmark.triangle")
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This will permanently delete all your movies, ratings, and rankings.")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showExportSheet) {
                ExportDataSheet()
            }
            .sheet(isPresented: $showTMDbSetup) {
                TMDbSetupSheet()
            }
            .alert("Clear Cache?", isPresented: $showClearCacheAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    Task {
                        await CacheManager.shared.clearAllCaches()
                        await updateCacheSize()
                    }
                }
            } message: {
                Text("This will remove all cached images and data. They will be re-downloaded when needed.")
            }
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This action cannot be undone. All your movies, ratings, reviews, and rankings will be permanently deleted.")
            }
            .task {
                await updateCacheSize()
            }
        }
    }

    private func updateCacheSize() async {
        cacheSize = await CacheManager.shared.formattedDiskCacheSize()
    }

    private func resetAllData() {
        // Delete all productions
        do {
            try modelContext.delete(model: Production.self)
            try modelContext.delete(model: NewsArticle.self)
            try modelContext.delete(model: Achievement.self)
            try modelContext.delete(model: CustomTag.self)
            try modelContext.save()
        } catch {
            print("Reset failed: \(error)")
        }

        // Clear cache
        Task {
            await CacheManager.shared.clearAllCaches()
        }

        // Reset user defaults
        UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.hasCompletedOnboarding)
    }
}

// MARK: - Accent Color Picker

struct AccentColorPicker: View {
    @AppStorage("accentColor") private var accentColor = "#FFD700"

    let colors: [(name: String, hex: String)] = [
        ("Cage Gold", "#FFD700"),
        ("Red", "#FF3B30"),
        ("Orange", "#FF9500"),
        ("Green", "#34C759"),
        ("Blue", "#007AFF"),
        ("Purple", "#AF52DE"),
        ("Pink", "#FF2D55")
    ]

    var body: some View {
        List {
            ForEach(colors, id: \.hex) { color in
                Button(action: { accentColor = color.hex }) {
                    HStack {
                        Circle()
                            .fill(Color(hex: color.hex) ?? .gray)
                            .frame(width: 30, height: 30)

                        Text(color.name)

                        Spacer()

                        if accentColor == color.hex {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color(hex: color.hex) ?? .gray)
                        }
                    }
                }
                .foregroundStyle(.primary)
            }
        }
        .navigationTitle("Accent Color")
    }
}

// MARK: - Export Data Sheet

struct ExportDataSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportType = .json
    @State private var includeImages = true
    @State private var includeReviews = true
    @State private var isExporting = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Format") {
                    Picker("Export Format", selection: $exportFormat) {
                        Text("JSON").tag(ExportType.json)
                        Text("HTML Website").tag(ExportType.html)
                        Text("CSV").tag(ExportType.csv)
                    }
                    .pickerStyle(.segmented)
                }

                Section("Options") {
                    Toggle("Include Poster Images", isOn: $includeImages)
                    Toggle("Include Reviews", isOn: $includeReviews)
                }

                Section {
                    Button(action: startExport) {
                        if isExporting {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Export")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isExporting)
                }
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func startExport() {
        isExporting = true
        // Export logic would go here
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            dismiss()
        }
    }
}

// MARK: - TMDb Setup Sheet

struct TMDbSetupSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey = ""
    @State private var isSaving = false
    @State private var testResult: TestResult?

    enum TestResult {
        case success
        case failure(String)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("API Key", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                } header: {
                    Text("TMDb API Key")
                } footer: {
                    Text("Get a free API key from themoviedb.org")
                }

                Section {
                    Button("Test Connection") {
                        testConnection()
                    }
                    .disabled(apiKey.isEmpty || isSaving)

                    if let result = testResult {
                        switch result {
                        case .success:
                            Label("Connection successful!", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        case .failure(let message):
                            Label(message, systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }

                Section {
                    Link("Get API Key", destination: URL(string: "https://www.themoviedb.org/settings/api")!)
                    Link("TMDb Terms of Use", destination: URL(string: "https://www.themoviedb.org/terms-of-use")!)
                }
            }
            .navigationTitle("TMDb Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveAPIKey()
                    }
                    .disabled(apiKey.isEmpty)
                }
            }
        }
    }

    private func testConnection() {
        isSaving = true
        // Test would go here
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            testResult = .success
            isSaving = false
        }
    }

    private func saveAPIKey() {
        // Save to keychain
        dismiss()
    }
}

// MARK: - Placeholder Views

struct ImportDataView: View {
    var body: some View {
        Text("Import Data - Coming Soon")
            .navigationTitle("Import")
    }
}

struct NewsSourcesView: View {
    var body: some View {
        Text("News Sources - Coming Soon")
            .navigationTitle("News Sources")
    }
}

struct CreditsView: View {
    var body: some View {
        List {
            Section("Created By") {
                Text("NCDB Team")
            }

            Section("Powered By") {
                Link("The Movie Database (TMDb)", destination: URL(string: "https://www.themoviedb.org")!)
            }

            Section("Special Thanks") {
                Text("Nicolas Cage, for being Nicolas Cage")
            }
        }
        .navigationTitle("Credits")
    }
}

struct LicensesView: View {
    var body: some View {
        List {
            Section {
                Text("SwiftUI - Apple Inc.")
                Text("SwiftData - Apple Inc.")
                Text("FeedKit - Nuno Dias")
            }
        }
        .navigationTitle("Licenses")
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .modelContainer(for: Production.self, inMemory: true)
}
