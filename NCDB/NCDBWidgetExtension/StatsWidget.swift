//
//  StatsWidget.swift
//  NCDBWidgetExtension
//
//  Created by Claude Code on 2025-12-25.
//

import WidgetKit
import SwiftUI

struct StatsWidget: Widget {
    let kind: String = "StatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsTimelineProvider()) { entry in
            StatsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Collection Stats")
        .description("View your Nicolas Cage collection statistics")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider

struct StatsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> StatsEntry {
        StatsEntry(date: Date(), data: StatsEntry.placeholderData)
    }

    func getSnapshot(in context: Context, completion: @escaping (StatsEntry) -> Void) {
        let entry: StatsEntry
        if let data = WidgetDataService.loadWidgetData() {
            entry = StatsEntry(date: Date(), data: data)
        } else {
            entry = StatsEntry(date: Date(), data: StatsEntry.placeholderData)
        }
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<StatsEntry>) -> Void) {
        let currentDate = Date()
        let entry: StatsEntry

        if let data = WidgetDataService.loadWidgetData() {
            entry = StatsEntry(date: currentDate, data: data)
        } else {
            entry = StatsEntry(date: currentDate, data: StatsEntry.placeholderData)
        }

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct StatsEntry: TimelineEntry {
    let date: Date
    let data: WidgetDataService.WidgetData

    static var placeholderData: WidgetDataService.WidgetData {
        WidgetDataService.WidgetData(
            watchedCount: 42,
            totalCount: 120,
            completionPercentage: 35.0,
            averageRating: 4.2,
            topRankedMovies: [],
            recentAchievements: [],
            lastUpdated: Date()
        )
    }
}

// MARK: - Widget View

struct StatsWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: StatsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
            // Header
            HStack {
                Image(systemName: "film.stack.fill")
                    .font(family == .systemSmall ? .caption2 : .caption)
                    .foregroundStyle(Color.cageGold)
                Text("NCDB")
                    .font(family == .systemSmall ? .caption2.bold() : .caption.bold())
                    .foregroundStyle(.white)
                Spacer()
            }

            Spacer(minLength: 0)

            // Stats
            switch family {
            case .systemSmall:
                smallLayout
            case .systemMedium:
                mediumLayout
            case .systemLarge:
                largeLayout
            default:
                smallLayout
            }
        }
        .padding(family == .systemSmall ? 14 : 16)
        .containerBackground(for: .widget) {
            if let posterPath = entry.data.topRankedMovies.first?.posterPath {
                PosterBackgroundView(posterPath: posterPath)
            } else {
                GradientBackgroundView()
            }
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(entry.data.watchedCount)")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(.white)

            Text("watched")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))

            HStack(spacing: 4) {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.cageGold)
                Text(String(format: "%.1f", entry.data.averageRating))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
    }

    private var mediumLayout: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                StatRow(
                    icon: "checkmark.circle.fill",
                    value: "\(entry.data.watchedCount)",
                    label: "Watched"
                )

                StatRow(
                    icon: "film.fill",
                    value: "\(entry.data.totalCount)",
                    label: "Total"
                )

                StatRow(
                    icon: "star.fill",
                    value: String(format: "%.1f", entry.data.averageRating),
                    label: "Avg Rating"
                )
            }

            Spacer()

            // Circular progress
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.2), lineWidth: 8)
                    .frame(width: 70, height: 70)

                Circle()
                    .trim(from: 0, to: entry.data.completionPercentage / 100.0)
                    .stroke(Color.cageGold, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 70, height: 70)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 0) {
                    Text("\(Int(entry.data.completionPercentage))")
                        .font(.title3.bold())
                        .foregroundStyle(.white)
                    Text("%")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
        }
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Stats grid
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    LargeStatCard(
                        icon: "checkmark.circle.fill",
                        value: "\(entry.data.watchedCount)",
                        label: "Watched",
                        color: .green
                    )

                    LargeStatCard(
                        icon: "film.fill",
                        value: "\(entry.data.totalCount)",
                        label: "Total",
                        color: .blue
                    )
                }

                HStack(spacing: 12) {
                    LargeStatCard(
                        icon: "star.fill",
                        value: String(format: "%.1f", entry.data.averageRating),
                        label: "Avg Rating",
                        color: .cageGold
                    )

                    LargeStatCard(
                        icon: "chart.pie.fill",
                        value: "\(Int(entry.data.completionPercentage))%",
                        label: "Complete",
                        color: .purple
                    )
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct StatRow: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.cageGold)
                .frame(width: 16)

            Text(value)
                .font(.headline)
                .foregroundStyle(.white)

            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
}

struct LargeStatCard: View {
    let icon: String
    let value: String
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.white)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Color Extension

extension Color {
    static let cageGold = Color(red: 1.0, green: 0.843, blue: 0.0) // #FFD700
}

#Preview(as: .systemSmall) {
    StatsWidget()
} timeline: {
    StatsEntry(date: .now, data: StatsEntry.placeholderData)
}

#Preview(as: .systemMedium) {
    StatsWidget()
} timeline: {
    StatsEntry(date: .now, data: StatsEntry.placeholderData)
}

#Preview(as: .systemLarge) {
    StatsWidget()
} timeline: {
    StatsEntry(date: .now, data: StatsEntry.placeholderData)
}
