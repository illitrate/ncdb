// NCDB Widget Views
// SwiftUI views for all widget sizes and types

import SwiftUI
import WidgetKit

// MARK: - Random Movie Widget Views

/// Random movie widget view - adapts to different sizes
struct RandomMovieWidgetView: View {
    let entry: RandomMovieEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            RandomMovieSmallView(entry: entry)
        case .systemMedium:
            RandomMovieMediumView(entry: entry)
        default:
            RandomMovieSmallView(entry: entry)
        }
    }
}

struct RandomMovieSmallView: View {
    let entry: RandomMovieEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "dice.fill")
                    .foregroundStyle(.cageGold)
                Text("Watch This")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let movie = entry.movie {
                // Movie info
                VStack(alignment: .leading, spacing: 4) {
                    Text(movie.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    if let year = movie.year {
                        Text(String(year))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if let rating = movie.rating {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", rating))
                                .fontWeight(.medium)
                        }
                        .font(.caption)
                    }
                }
            } else {
                Text("No movies available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .widgetURL(entry.movie.map { WidgetDeepLink.randomMovie(id: $0.id).url })
    }
}

struct RandomMovieMediumView: View {
    let entry: RandomMovieEntry

    var body: some View {
        HStack(spacing: 16) {
            // Poster placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.cageGold.opacity(0.2))
                .frame(width: 80)
                .overlay {
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundStyle(.cageGold)
                }

            VStack(alignment: .leading, spacing: 8) {
                // Header
                HStack {
                    Image(systemName: "dice.fill")
                        .foregroundStyle(.cageGold)
                    Text("Random Pick")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }

                if let movie = entry.movie {
                    Text(movie.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .lineLimit(2)

                    HStack(spacing: 12) {
                        if let year = movie.year {
                            Text(String(year))
                                .foregroundStyle(.secondary)
                        }

                        if let rating = movie.rating {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .foregroundStyle(.yellow)
                                Text(String(format: "%.1f", rating))
                            }
                        }
                    }
                    .font(.subheadline)
                } else {
                    Text("No movies available")
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .widgetURL(entry.movie.map { WidgetDeepLink.randomMovie(id: $0.id).url })
    }
}

// MARK: - Watch Progress Widget Views

struct WatchProgressWidgetView: View {
    let entry: WatchProgressEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            WatchProgressSmallView(entry: entry)
        case .systemMedium:
            WatchProgressMediumView(entry: entry)
        case .systemLarge:
            WatchProgressLargeView(entry: entry)
        default:
            WatchProgressSmallView(entry: entry)
        }
    }
}

struct WatchProgressSmallView: View {
    let entry: WatchProgressEntry

    var body: some View {
        VStack(spacing: 12) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.cageGold.opacity(0.2), lineWidth: 8)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(Color.cageGold, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(entry.progress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
            .frame(width: 80, height: 80)

            Text("\(entry.watchedCount)/\(entry.totalCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(WidgetDeepLink.watchProgress.url)
    }
}

struct WatchProgressMediumView: View {
    let entry: WatchProgressEntry

    var body: some View {
        HStack(spacing: 20) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.cageGold.opacity(0.2), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(Color.cageGold, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(entry.progress * 100))%")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Complete")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 100, height: 100)

            VStack(alignment: .leading, spacing: 8) {
                Text("Watch Progress")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Text("\(entry.watchedCount) of \(entry.totalCount)")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("movies watched")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("\(entry.totalCount - entry.watchedCount) remaining")
                    .font(.caption)
                    .foregroundStyle(.cageGold)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(WidgetDeepLink.watchProgress.url)
    }
}

struct WatchProgressLargeView: View {
    let entry: WatchProgressEntry

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Watch Progress")
                    .font(.headline)
                Spacer()
                Text("\(Int(entry.progress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.cageGold)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cageGold.opacity(0.2))

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cageGold)
                        .frame(width: geo.size.width * entry.progress)
                }
            }
            .frame(height: 16)

            // Stats
            HStack {
                StatBox(value: "\(entry.watchedCount)", label: "Watched")
                StatBox(value: "\(entry.totalCount - entry.watchedCount)", label: "Remaining")
                StatBox(value: "\(entry.totalCount)", label: "Total")
            }

            Divider()

            // Recent movies
            if !entry.recentMovies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recently Watched")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    ForEach(entry.recentMovies.prefix(3)) { movie in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                            Text(movie.title)
                                .lineLimit(1)
                            Spacer()
                            if let year = movie.year {
                                Text(String(year))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.caption)
                    }
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(WidgetDeepLink.watchProgress.url)
    }
}

struct StatBox: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Streak Widget View

struct StreakWidgetView: View {
    let entry: StreakEntry

    var body: some View {
        VStack(spacing: 12) {
            // Flame icon
            Image(systemName: entry.isStreakActive ? "flame.fill" : "flame")
                .font(.largeTitle)
                .foregroundStyle(entry.isStreakActive ? .orange : .gray)
                .symbolEffect(.bounce, value: entry.currentStreak)

            // Streak count
            Text("\(entry.currentStreak)")
                .font(.system(size: 36, weight: .bold, design: .rounded))

            Text("day streak")
                .font(.caption)
                .foregroundStyle(.secondary)

            if !entry.isStreakActive && entry.currentStreak > 0 {
                Text("Watch today!")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(WidgetDeepLink.streak.url)
    }
}

// MARK: - Stats Widget View

struct StatsWidgetView: View {
    let entry: StatsEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundStyle(.cageGold)
                Text("Quick Stats")
                    .font(.headline)
                Spacer()
            }

            // Stats grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatItem(
                    value: "\(entry.stats.totalWatched)",
                    label: "Watched",
                    icon: "eye.fill"
                )

                StatItem(
                    value: String(format: "%.1f", entry.stats.averageRating),
                    label: "Avg Rating",
                    icon: "star.fill"
                )

                StatItem(
                    value: entry.stats.watchTimeFormatted,
                    label: "Watch Time",
                    icon: "clock.fill"
                )
            }

            if family == .systemLarge {
                Divider()

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    StatItem(
                        value: "\(entry.stats.achievementsUnlocked)/\(entry.stats.totalAchievements)",
                        label: "Achievements",
                        icon: "trophy.fill"
                    )

                    StatItem(
                        value: "\(Int(Double(entry.stats.totalWatched) / Double(entry.stats.totalMovies) * 100))%",
                        label: "Complete",
                        icon: "checkmark.circle.fill"
                    )
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(WidgetDeepLink.stats.url)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.cageGold)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Lock Screen Widget Views

@available(iOSApplicationExtension 16.0, *)
struct RandomMovieLockScreenView: View {
    let entry: RandomMovieEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                Image(systemName: "dice.fill")
                    .font(.title2)
            }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Label("Random Pick", systemImage: "dice.fill")
                    .font(.caption)
                if let movie = entry.movie {
                    Text(movie.title)
                        .font(.headline)
                        .lineLimit(1)
                }
            }

        case .accessoryInline:
            if let movie = entry.movie {
                Label(movie.title, systemImage: "film")
            } else {
                Label("Random Movie", systemImage: "dice.fill")
            }

        default:
            EmptyView()
        }
    }
}

@available(iOSApplicationExtension 16.0, *)
struct StreakLockScreenView: View {
    let entry: StreakEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 2) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                    Text("\(entry.currentStreak)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Label("Watch Streak", systemImage: "flame.fill")
                    .font(.caption)
                Text("\(entry.currentStreak) days")
                    .font(.headline)
            }

        case .accessoryInline:
            Label("\(entry.currentStreak) day streak", systemImage: "flame.fill")

        default:
            EmptyView()
        }
    }
}

// MARK: - Cage Gold Color

extension Color {
//    static let cageGold = Color(red: 1.0, green: 0.84, blue: 0.0)
}
