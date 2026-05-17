//
//  ExportPreviewView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import WebKit

/// Preview view for generated website with file browser
struct ExportPreviewView: View {
    @Environment(\.dismiss) private var dismiss

    let websiteURL: URL

    @State private var selectedFile: URL?
    @State private var fileList: [URL] = []
    @State private var isLoadingFiles = true
    @State private var showingFullscreenBrowser = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()

                if isLoadingFiles {
                    ProgressView("Loading files...")
                        .tint(Color.cageGold)
                } else {
                    HStack(spacing: 0) {
                        // File Browser Sidebar
                        fileBrowser
                            .frame(width: 250)

                        Divider()

                        // Preview Area
                        previewArea
                    }
                }
            }
            .navigationTitle("Website Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            shareWebsite()
                        } label: {
                            Label("Share Files", systemImage: "square.and.arrow.up")
                        }

                        Button {
                            openInFinder()
                        } label: {
                            Label("Show in Files", systemImage: "folder")
                        }

                        if selectedFile?.pathExtension == "html" {
                            Button {
                                openInBrowser()
                            } label: {
                                Label("View full screen", systemImage: "safari")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .task {
                await loadFileList()
            }
            .fullScreenCover(isPresented: $showingFullscreenBrowser) {
                if let fileURL = selectedFile {
                    FullscreenBrowserView(url: fileURL)
                }
            }
        }
    }

    // MARK: - File Browser

    private var fileBrowser: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Files")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Text("\(fileList.count)")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
            }
            .padding()
            .background(Color(hex: "1A1A1A").opacity(0.5))

            Divider()

            // File List
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(fileList, id: \.path) { fileURL in
                        fileRow(for: fileURL)
                    }
                }
            }
        }
        .background(Color(hex: "1A1A1A").opacity(0.3))
    }

    private func fileRow(for fileURL: URL) -> some View {
        Button {
            selectedFile = fileURL
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: iconName(for: fileURL))
                    .foregroundStyle(iconColor(for: fileURL))
                    .frame(width: 20)

                VStack(alignment: .leading, spacing: 2) {
                    Text(fileURL.lastPathComponent)
                        .font(.subheadline)
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(1)

                    if let size = fileSize(for: fileURL) {
                        Text(size)
                            .font(.caption2)
                            .foregroundStyle(Color.secondaryText)
                    }
                }

                Spacer()

                if selectedFile == fileURL {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.cageGold)
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, Spacing.sm)
            .background(selectedFile == fileURL ? Color.cageGold.opacity(0.15) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Preview Area

    private var previewArea: some View {
        VStack(spacing: 0) {
            if let selectedFile = selectedFile {
                // File Info Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(selectedFile.lastPathComponent)
                            .font(.headline)
                            .foregroundStyle(Color.primaryText)

                        if let size = fileSize(for: selectedFile) {
                            Text(size)
                                .font(.caption)
                                .foregroundStyle(Color.secondaryText)
                        }
                    }

                    Spacer()
                }
                .padding()
                .background(Color(hex: "1A1A1A").opacity(0.5))

                Divider()

                // Preview Content
                if selectedFile.pathExtension == "html" {
                    WebView(url: selectedFile)
                } else if selectedFile.pathExtension == "css" || selectedFile.pathExtension == "txt" {
                    TextFileView(url: selectedFile)
                } else if ["jpg", "jpeg", "png", "gif"].contains(selectedFile.pathExtension.lowercased()) {
                    ImageFileView(url: selectedFile)
                } else {
                    placeholderView(message: "No preview available for \(selectedFile.pathExtension.uppercased()) files")
                }
            } else {
                placeholderView(message: "Select a file to preview")
            }
        }
    }

    private func placeholderView(message: String) -> some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(Color.secondaryText)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - File Helpers

    private func iconName(for url: URL) -> String {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "html":
            return "doc.text.fill"
        case "css":
            return "paintbrush.fill"
        case "jpg", "jpeg", "png", "gif":
            return "photo.fill"
        case "js":
            return "chevron.left.forwardslash.chevron.right"
        default:
            if url.hasDirectoryPath {
                return "folder.fill"
            }
            return "doc.fill"
        }
    }

    private func iconColor(for url: URL) -> Color {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "html":
            return .orange
        case "css":
            return .blue
        case "jpg", "jpeg", "png", "gif":
            return .green
        case "js":
            return .yellow
        default:
            if url.hasDirectoryPath {
                return Color.cageGold
            }
            return Color.secondaryText
        }
    }

    private func fileSize(for url: URL) -> String? {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? Int64 else {
            return nil
        }

        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    // MARK: - Actions

    private func loadFileList() async {
        isLoadingFiles = true

        let fileManager = FileManager.default

        var files: [URL] = []

        if let enumerator = fileManager.enumerator(
            at: websiteURL,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey],
            options: [.skipsHiddenFiles]
        ) {
            for case let fileURL as URL in enumerator {
                files.append(fileURL)
            }
        }

        // Sort: directories first, then by name
        files.sort { url1, url2 in
            let isDir1 = (try? url1.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
            let isDir2 = (try? url2.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false

            if isDir1 != isDir2 {
                return isDir1
            }
            return url1.lastPathComponent < url2.lastPathComponent
        }

        await MainActor.run {
            fileList = files
            // Auto-select index.html if it exists
            selectedFile = files.first { $0.lastPathComponent == "index.html" }
            isLoadingFiles = false
        }
    }

    private func shareWebsite() {
        let activityVC = UIActivityViewController(
            activityItems: [websiteURL],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            rootVC.present(activityVC, animated: true)
        }
    }

    private func openInFinder() {
        #if targetEnvironment(simulator)
        // On simulator, just print the path
        print("Website location: \(websiteURL.path)")
        #else
        // On device, open in Files app
        UIApplication.shared.open(websiteURL)
        #endif
    }

    private func openInBrowser() {
        guard selectedFile != nil else { return }
        showingFullscreenBrowser = true
    }
}

// MARK: - WebView

struct WebView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // No updates needed
    }
}

// MARK: - TextFileView

struct TextFileView: View {
    let url: URL

    @State private var content = ""
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(Color.cageGold)
            } else {
                ScrollView {
                    Text(content)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(Color.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .textSelection(.enabled)
                }
            }
        }
        .task {
            await loadContent()
        }
    }

    private func loadContent() async {
        if let data = try? Data(contentsOf: url),
           let text = String(data: data, encoding: .utf8) {
            await MainActor.run {
                content = text
                isLoading = false
            }
        }
    }
}

// MARK: - ImageFileView

struct ImageFileView: View {
    let url: URL

    var body: some View {
        ScrollView([.horizontal, .vertical]) {
            if let uiImage = UIImage(contentsOfFile: url.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding()
            } else {
                Text("Failed to load image")
                    .foregroundStyle(Color.secondaryText)
            }
        }
    }
}

// MARK: - Fullscreen Browser View

struct FullscreenBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    let url: URL

    var body: some View {
        NavigationStack {
            WebView(url: url)
                .ignoresSafeArea()
                .navigationTitle("Website Preview")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
    }
}

#Preview {
    ExportPreviewView(websiteURL: FileManager.default.temporaryDirectory)
}
