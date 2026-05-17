//
//  ExportDataView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-25.
//

import SwiftUI
import SwiftData

/// Simple data export view for JSON and CSV exports
struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var productions: [Production]

    @State private var selectedFormat: ExportFormat = .json
    @State private var isExporting = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    private let exportService = ExportService.shared

    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"

        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            }
        }

        var icon: String {
            switch self {
            case .json: return "doc.text"
            case .csv: return "tablecells"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()

                VStack(spacing: Spacing.xl) {
                    // Header
                    VStack(spacing: Spacing.sm) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 60))
                            .foregroundStyle(Color.cageGold)

                        Text("Export Your Data")
                            .font(.title.bold())
                            .foregroundStyle(Color.primaryText)

                        Text("Export your collection to share or backup")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Spacing.xl)

                    // Format Selection
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Export Format")
                            .font(.headline)
                            .foregroundStyle(Color.primaryText)

                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Button {
                                selectedFormat = format
                                HapticManager.shared.buttonTap()
                            } label: {
                                HStack(spacing: Spacing.md) {
                                    Image(systemName: format.icon)
                                        .font(.title2)
                                        .foregroundStyle(selectedFormat == format ? Color.cageGold : Color.secondaryText)
                                        .frame(width: 40)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(format.rawValue)
                                            .font(.headline)
                                            .foregroundStyle(Color.primaryText)

                                        Text(format == .json ? "Complete data with all details" : "Spreadsheet-compatible format")
                                            .font(.caption)
                                            .foregroundStyle(Color.secondaryText)
                                    }

                                    Spacer()

                                    if selectedFormat == format {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.cageGold)
                                    }
                                }
                                .padding(Spacing.md)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.secondaryBackground)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedFormat == format ? Color.cageGold : Color.clear, lineWidth: 2)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)

                    // Stats
                    VStack(spacing: Spacing.sm) {
                        Text("Export will include:")
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)

                        HStack(spacing: Spacing.lg) {
                            StatBadge(count: productions.count, label: "Movies")
                            StatBadge(count: productions.filter(\.watched).count, label: "Watched")
                            StatBadge(count: productions.filter(\.isFavorite).count, label: "Favorites")
                        }
                    }
                    .padding(.horizontal, Spacing.lg)

                    Spacer()

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }

                    // Export Button
                    VStack(spacing: Spacing.md) {
                        GlassButton(
                            title: isExporting ? "Exporting..." : "Export \(selectedFormat.rawValue)",
                            style: .primary
                        ) {
                            Task {
                                await performExport()
                            }
                        }
                        .disabled(isExporting)

                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundStyle(Color.secondaryText)
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func performExport() async {
        isExporting = true
        errorMessage = nil

        do {
            let fileURL: URL

            switch selectedFormat {
            case .json:
                fileURL = try await exportService.exportToJSON()
            case .csv:
                fileURL = try await exportService.exportWatchHistoryToCSV()
            }

            exportedFileURL = fileURL
            showShareSheet = true

            HapticManager.shared.success()
            Logger.shared.info("Export successful: \(fileURL.lastPathComponent)", category: .general)

        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            HapticManager.shared.error()
            Logger.shared.error("Export failed: \(error)", category: .general)
        }

        isExporting = false
    }
}

// MARK: - Supporting Views

private struct StatBadge: View {
    let count: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundStyle(Color.cageGold)

            Text(label)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
        }
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExportDataView()
        .modelContainer(for: Production.self, inMemory: true)
}
