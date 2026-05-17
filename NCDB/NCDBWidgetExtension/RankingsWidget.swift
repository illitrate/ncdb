//
//  RankingsWidget.swift
//  NCDBWidgetExtension
//
//  Created by Claude Code on 2025-12-25.
//

import WidgetKit
import SwiftUI

struct RankingsWidget: Widget {
    let kind: String = "RankingsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: RankingsTimelineProvider()) { entry in
            RankingsWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Top Rankings")
        .description("Your top-ranked Nicolas Cage movies")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider

struct RankingsTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> RankingsEntry {
        RankingsEntry(date: Date(), data: RankingsEntry.placeholderData)
    }

    func getSnapshot(in context: Context, completion: @escaping (RankingsEntry) -> Void) {
        let entry: RankingsEntry
        if let data = WidgetDataService.loadWidgetData() {
            entry = RankingsEntry(date: Date(), data: data)
        } else {
            entry = RankingsEntry(date: Date(), data: RankingsEntry.placeholderData)
        }
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RankingsEntry>) -> Void) {
        let currentDate = Date()
        let entry: RankingsEntry

        if let data = WidgetDataService.loadWidgetData() {
            entry = RankingsEntry(date: currentDate, data: data)
        } else {
            entry = RankingsEntry(date: currentDate, data: RankingsEntry.placeholderData)
        }

        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Timeline Entry

struct RankingsEntry: TimelineEntry {
    let date: Date
    let data: WidgetDataService.WidgetData

    static var placeholderData: WidgetDataService.WidgetData {
        WidgetDataService.WidgetData(
            watchedCount: 42,
            totalCount: 120,
            completionPercentage: 35.0,
            averageRating: 4.2,
            topRankedMovies: [
                .init(title: "Face/Off", year: 1997, rank: 1, posterPath: nil, rating: 5.0),
                .init(title: "The Unbearable Weight of Massive Talent", year: 2022, rank: 2, posterPath: nil, rating: 4.8),
                .init(title: "Con Air", year: 1997, rank: 3, posterPath: nil, rating: 4.7)
            ],
            recentAchievements: [],
            lastUpdated: Date()
        )
    }
}

// MARK: - Widget View

struct RankingsWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: RankingsEntry

    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 6 : 8) {
            // Header
            HStack {
                Image(systemName: "trophy.fill")
                    .font(family == .systemSmall ? .caption2 : .caption)
                    .foregroundStyle(Color.cageGold)
                Text("Top Ranked")
                    .font(family == .systemSmall ? .caption2.bold() : .caption.bold())
                    .foregroundStyle(.white)
                Spacer()
            }

//            Spacer(minLength: 0)

            // Rankings
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
        Group {
            if let topMovie = entry.data.topRankedMovies.first {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top, spacing: 4) {
                        Text("#1")
                            .font(.caption.bold())
                            .foregroundStyle(Color.cageGold)

                        if let rating = topMovie.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                Text(String(format: "%.1f", rating))
                                    .font(.caption2)
                            }
                            .foregroundStyle(Color.cageGold)
                        }
                    }

                    Text(topMovie.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Text(String(topMovie.year))
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                }
            } else {
                Text("No rankings yet")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var mediumLayout: some View {
        VStack(spacing: 6) {
            ForEach(entry.data.topRankedMovies.prefix(3), id: \.title) { movie in
                RankingRow(movie: movie)
            }

            if entry.data.topRankedMovies.isEmpty {
                Text("No rankings yet")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var largeLayout: some View {
        VStack(spacing: 8) {
            ForEach(entry.data.topRankedMovies.prefix(3), id: \.title) { movie in
                LargeRankingCard(movie: movie)
            }

            if entry.data.topRankedMovies.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.3))

                    Text("No rankings yet")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

// MARK: - Supporting Views

struct RankingRow: View {
    let movie: WidgetDataService.WidgetData.RankedMovie

    var body: some View {
        HStack(spacing: 10) {
            // Rank badge
            ZStack {
                Circle()
                    .fill(Color.cageGold)
                    .frame(width: 24, height: 24)

                Text("#\(movie.rank)")
                    .font(.caption2.bold())
                    .foregroundStyle(.black)
            }

            // Movie info
//            VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                VStack(alignment: .leading){
                    Text(movie.title)
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .lineLimit(1)


                        Text(String(movie.year))
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.7))
                }
                Spacer()
            
                    
                HStack {
                    if let rating = movie.rating {

                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text(String(format: "%.1f", rating))
                                .font(.caption2)
                        }
                        .foregroundStyle(Color.cageGold)
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct LargeRankingCard: View {
    let movie: WidgetDataService.WidgetData.RankedMovie

    var body: some View {
        HStack(spacing: 12) {
            // Poster thumbnail
            if let posterPath = movie.posterPath,
               let cachedImage = WidgetDataService.loadSharedPosterImage(posterPath: posterPath) {
                Image(uiImage: cachedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 75)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                PosterPlaceholder()
            }

            // Movie details
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(Color.cageGold)
                            .frame(width: 28, height: 28)

                        Text("#\(movie.rank)")
                            .font(.caption.bold())
                            .foregroundStyle(.black)
                    }

                    if let rating = movie.rating {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                            Text(String(format: "%.1f", rating))
                                .font(.caption.bold())
                        }
                        .foregroundStyle(Color.cageGold)
                    }
                }

                Text(movie.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(String(movie.year))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct PosterPlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(.ultraThinMaterial)
            .frame(width: 50, height: 75)
            .overlay(
                Image(systemName: "film")
                    .foregroundStyle(.white.opacity(0.3))
            )
    }
}

#Preview(as: .systemSmall) {
    RankingsWidget()
} timeline: {
    RankingsEntry(date: .now, data: RankingsEntry.placeholderData)
}

#Preview(as: .systemMedium) {
    RankingsWidget()
} timeline: {
    RankingsEntry(date: .now, data: RankingsEntry.placeholderData)
}

#Preview(as: .systemLarge) {
    RankingsWidget()
} timeline: {
    RankingsEntry(date: .now, data: RankingsEntry.placeholderData)
}
