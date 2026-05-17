//
//  AchievementWidget.swift
//  NCDBWidgetExtension
//
//  Created by Claude Code on 2025-12-25.
//

import WidgetKit
import SwiftUI

struct AchievementWidget: Widget {
    let kind: String = "AchievementWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: AchievementTimelineProvider()) { entry in
            AchievementWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Recent Achievements")
        .description("Your latest unlocked achievements")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider

struct AchievementTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> AchievementEntry {
        AchievementEntry(date: Date(), data: AchievementEntry.placeholderData)
    }

    func getSnapshot(in context: Context, completion: @escaping (AchievementEntry) -> Void) {
        let entry: AchievementEntry
        if let data = WidgetDataService.loadWidgetData() {
            entry = AchievementEntry(date: Date(), data: data)
        } else {
            entry = AchievementEntry(date: Date(), data: AchievementEntry.placeholderData)
        }
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AchievementEntry>) -> Void) {
        let currentDate = Date()
        let entry: AchievementEntry

        if let data = WidgetDataService.loadWidgetData() {
            entry = AchievementEntry(date: currentDate, data: data)
        } else {
            entry = AchievementEntry(date: currentDate, data: AchievementEntry.placeholderData)
        }

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct AchievementEntry: TimelineEntry {
    let date: Date
    let data: WidgetDataService.WidgetData

    static var placeholderData: WidgetDataService.WidgetData {
        WidgetDataService.WidgetData(
            watchedCount: 42,
            totalCount: 120,
            completionPercentage: 35.0,
            averageRating: 4.2,
            topRankedMovies: [],
            recentAchievements: [
                .init(title: "First Watch", icon: "play.circle.fill", unlockedAt: Date()),
                .init(title: "Marathon Runner", icon: "figure.run", unlockedAt: Date()),
                .init(title: "Top Fan", icon: "star.fill", unlockedAt: Date())
            ],
            lastUpdated: Date()
        )
    }
}

// MARK: - Widget View

struct AchievementWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: AchievementEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
            // Header
            HStack {
                Image(systemName: "trophy.fill")
                    .font(family == .systemSmall ? .caption2 : .caption)
                    .foregroundStyle(Color.cageGold)
                Text("Achievements")
                    .font(family == .systemSmall ? .caption2.bold() : .caption.bold())
                    .foregroundStyle(.white)
                Spacer()
            }

            Spacer(minLength: 0)

            // Achievements
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
            if let posterPath = entry.data.topRankedMovies.randomElement()?.posterPath {
                PosterBackgroundView(posterPath: posterPath)
            } else {
                GradientBackgroundView()
            }
        }
    }

    private var smallLayout: some View {
        Group {
            if let latestAchievement = entry.data.recentAchievements.first {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: latestAchievement.icon)
                        .font(.title)
                        .foregroundStyle(Color.cageGold)

                    Text(latestAchievement.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(timeAgo(from: latestAchievement.unlockedAt))
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.7))
                }
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "trophy.fill")
                        .font(.title)
                        .foregroundStyle(.white.opacity(0.3))

                    Text("No achievements yet")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
        }
    }

    private var mediumLayout: some View {
        HStack(spacing: 12) {
            // Latest achievement - large
            if let latestAchievement = entry.data.recentAchievements.first {
                VStack(alignment: .leading, spacing: 6) {
                    Image(systemName: latestAchievement.icon)
                        .font(.largeTitle)
                        .foregroundStyle(Color.cageGold)

                    Text(latestAchievement.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(timeAgo(from: latestAchievement.unlockedAt))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Additional achievements - small
                VStack(spacing: 8) {
                    ForEach(entry.data.recentAchievements.dropFirst().prefix(2), id: \.title) { achievement in
                        HStack(spacing: 6) {
                            Image(systemName: achievement.icon)
                                .font(.caption)
                                .foregroundStyle(Color.cageGold)
                                .frame(width: 16)

                            Text(achievement.title)
                                .font(.caption2)
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.3))

                    Text("No achievements yet")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var largeLayout: some View {
        VStack(spacing: 8) {
            ForEach(entry.data.recentAchievements.prefix(4), id: \.title) { achievement in
                AchievementCard(achievement: achievement)
            }

            if entry.data.recentAchievements.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.white.opacity(0.3))

                    Text("No achievements yet")
                        .font(.headline)
                        .foregroundStyle(.white.opacity(0.7))

                    Text("Start watching movies to unlock achievements!")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 min ago" : "\(minute) mins ago"
        } else {
            return "Just now"
        }
    }
}

// MARK: - Supporting Views

struct AchievementCard: View {
    let achievement: WidgetDataService.WidgetData.Achievement

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.cageGold.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundStyle(Color.cageGold)
            }

            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)

                Text(timeAgo(from: achievement.unlockedAt))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func timeAgo(from date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let day = components.day, day > 0 {
            return day == 1 ? "1 day ago" : "\(day) days ago"
        } else if let hour = components.hour, hour > 0 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        } else if let minute = components.minute, minute > 0 {
            return minute == 1 ? "1 min ago" : "\(minute) mins ago"
        } else {
            return "Just now"
        }
    }
}

#Preview(as: .systemSmall) {
    AchievementWidget()
} timeline: {
    AchievementEntry(date: .now, data: AchievementEntry.placeholderData)
}

#Preview(as: .systemMedium) {
    AchievementWidget()
} timeline: {
    AchievementEntry(date: .now, data: AchievementEntry.placeholderData)
}

#Preview(as: .systemLarge) {
    AchievementWidget()
} timeline: {
    AchievementEntry(date: .now, data: AchievementEntry.placeholderData)
}
