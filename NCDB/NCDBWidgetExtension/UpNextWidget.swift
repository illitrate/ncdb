//
//  UpNextWidget.swift
//  NCDBWidgetExtension
//
//  An interactive widget: pick something off the watchlist and mark it watched
//  without opening the app.
//

import AppIntents
import SwiftUI
import WidgetKit

struct UpNextWidget: Widget {
    let kind: String = "UpNextWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: UpNextTimelineProvider()) { entry in
            UpNextWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Up Next")
        .description("Something from your watchlist you haven't seen yet.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}

// MARK: - Timeline Provider

struct UpNextTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> UpNextEntry {
        UpNextEntry(date: Date(), film: UpNextEntry.placeholderFilm, remaining: 12)
    }

    func getSnapshot(in context: Context, completion: @escaping (UpNextEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UpNextEntry>) -> Void) {
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: Date()) ?? Date()
        completion(Timeline(entries: [makeEntry()], policy: .after(nextUpdate)))
    }

    private func makeEntry() -> UpNextEntry {
        guard let data = WidgetDataService.loadWidgetData() else {
            return UpNextEntry(date: Date(), film: nil, remaining: 0)
        }

        return UpNextEntry(
            date: Date(),
            film: data.upNext.first,
            remaining: max(0, data.totalCount - data.watchedCount)
        )
    }
}

// MARK: - Entry

struct UpNextEntry: TimelineEntry {
    let date: Date
    let film: WidgetDataService.WidgetData.RankedMovie?
    let remaining: Int

    static var placeholderFilm: WidgetDataService.WidgetData.RankedMovie {
        .init(id: UUID(), title: "Pig", year: 2021, rank: 0, posterPath: nil, rating: nil)
    }
}

// MARK: - View

struct UpNextWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: UpNextEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryRectangular:
                accessoryLayout
            default:
                homeScreenLayout
            }
        }
        .widgetURL(entry.film.flatMap { NCDBDeepLink.film(id: $0.id) } ?? NCDBDeepLink.watchlist)
        .containerBackground(for: .widget) {
            if family == .accessoryRectangular {
                Color.clear
            } else {
                GradientBackgroundView()
            }
        }
    }

    // MARK: Home Screen

    private var homeScreenLayout: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "popcorn.fill")
                    .font(.caption2)
                    .foregroundStyle(Color.cageGold)
                Text("Up Next")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                Spacer()
                if entry.remaining > 0 {
                    Text("\(entry.remaining) left")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.6))
                }
            }

            if let film = entry.film {
                Text(film.title)
                    .font(family == .systemSmall ? .subheadline.bold() : .headline)
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text(String(film.year))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))

                Spacer(minLength: 0)

                // Interactive: runs MarkFilmWatchedIntent in the background and
                // reloads the timeline. No app launch.
                Button(intent: markWatchedIntent(for: film)) {
                    Label("Watched", systemImage: "checkmark.circle.fill")
                        .font(.caption.bold())
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.cageGold)
                .foregroundStyle(.black)
            } else {
                Spacer(minLength: 0)
                Text("Nothing left to watch.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer(minLength: 0)
            }
        }
        .padding(family == .systemSmall ? 12 : 14)
    }

    // MARK: Lock Screen

    private var accessoryLayout: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Up Next")
                .font(.caption2.bold())
                .widgetAccentable()

            if let film = entry.film {
                Text(film.title)
                    .font(.headline)
                    .lineLimit(1)

                Text(String(film.year))
                    .font(.caption2)
            } else {
                Text("Watchlist empty")
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func markWatchedIntent(for film: WidgetDataService.WidgetData.RankedMovie) -> MarkFilmWatchedIntent {
        let intent = MarkFilmWatchedIntent()
        intent.film = FilmEntity(
            id: film.id,
            title: film.title,
            releaseYear: film.year,
            watched: false,
            rating: film.rating,
            rankingPosition: nil
        )
        return intent
    }
}

#Preview(as: .systemSmall) {
    UpNextWidget()
} timeline: {
    UpNextEntry(date: .now, film: UpNextEntry.placeholderFilm, remaining: 12)
}

#Preview(as: .systemMedium) {
    UpNextWidget()
} timeline: {
    UpNextEntry(date: .now, film: UpNextEntry.placeholderFilm, remaining: 12)
}
