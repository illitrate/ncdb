//
//  NCDBControls.swift
//  NCDBWidgetExtension
//
//  Control Centre, Lock Screen and Action Button controls.
//

import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Log a Watch

/// One tap logs a viewing of the next film on the watchlist.
///
/// Rides entirely on LogNextWatchIntent, which runs without launching the app —
/// so this works from Control Centre, the Lock Screen, or the Action Button.
struct LogWatchControl: ControlWidget {

    static let kind = "com.ncdb.control.logwatch"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind) {
            ControlWidgetButton(action: LogNextWatchIntent()) {
                Label("Log a Watch", systemImage: "popcorn.fill")
            }
            .tint(.cageGold)
        }
        .displayName("Log a Watch")
        .description("Mark the next film on your watchlist as watched.")
    }
}

// MARK: - Collection Progress

/// Read-only control showing how far through the filmography you are.
struct CompletionControl: ControlWidget {

    static let kind = "com.ncdb.control.completion"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(kind: Self.kind, provider: CompletionValueProvider()) { progress in
            ControlWidgetButton(action: OpenStatsIntent()) {
                Label {
                    Text("\(progress.watched) of \(progress.total)")
                } icon: {
                    Image(systemName: "chart.pie.fill")
                }
            }
            .tint(.cageGold)
        }
        .displayName("Cage Progress")
        .description("How much of the filmography you've watched.")
    }
}

struct CompletionValue {
    let watched: Int
    let total: Int
}

struct CompletionValueProvider: ControlValueProvider {

    let previewValue = CompletionValue(watched: 42, total: 120)

    func currentValue() async throws -> CompletionValue {
        guard let data = WidgetDataService.loadWidgetData() else {
            return CompletionValue(watched: 0, total: 0)
        }
        return CompletionValue(watched: data.watchedCount, total: data.totalCount)
    }
}

// MARK: - Supporting Intent

/// Opens the stats screen. Controls need an action, and for a read-only control
/// the useful one is "show me the detail behind this number".
struct OpenStatsIntent: AppIntent {

    static let title: LocalizedStringResource = "Open Stats"
    static let openAppWhenRun = true

    init() {}

    @MainActor
    func perform() async throws -> some IntentResult {
        .result()
    }
}
