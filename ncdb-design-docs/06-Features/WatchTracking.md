# NCDB Watch Tracking System

## Overview

The watch tracking system records when, where, and how users watch Nicolas Cage movies. It goes beyond simple "watched/unwatched" status to create a rich viewing diary with context and memories.

## Core Concepts

### Watch Philosophy

1. **Beyond Binary**: Not just watched/unwatched, but a complete viewing history
2. **Contextual Memory**: Where you watched, who with, how you felt
3. **Rewatch Support**: Many Cage fans rewatch favorites multiple times
4. **Personal Journal**: Each viewing is a memory worth capturing
5. **Stats-Friendly**: Data that powers meaningful statistics

## Data Models

### Production Watch Properties

```swift
@Model
final class Production {
    // ... other properties

    /// Whether the movie has been watched at least once
    var watched: Bool = false

    /// Date of first (or most recent) watch
    var dateWatched: Date?

    /// Total number of times watched
    var watchCount: Int = 0

    /// Detailed watch events
    @Relationship(deleteRule: .cascade)
    var watchEvents: [WatchEvent] = []

    /// Whether currently on watchlist (planning to watch)
    var onWatchlist: Bool = false

    /// Date added to watchlist
    var watchlistDate: Date?
}
```

### WatchEvent Entity

```swift
@Model
final class WatchEvent {
    var id: UUID
    var watchedDate: Date
    var location: String?       // Where they watched
    var notes: String?          // Personal notes/memory
    var mood: String?           // How they felt
    var companions: String?     // Who they watched with
    var format: WatchFormat?    // How they watched
    var isRewatch: Bool         // First time or rewatch
    var production: Production?

    init(watchedDate: Date = Date()) {
        self.id = UUID()
        self.watchedDate = watchedDate
        self.isRewatch = false
    }
}

enum WatchFormat: String, Codable, CaseIterable {
    case theater = "Theater"
    case streaming = "Streaming"
    case bluray = "Blu-ray/DVD"
    case digital = "Digital Purchase"
    case tv = "TV Broadcast"
    case other = "Other"

    var icon: String {
        switch self {
        case .theater: return "popcorn.fill"
        case .streaming: return "play.tv.fill"
        case .bluray: return "opticaldisc.fill"
        case .digital: return "icloud.fill"
        case .tv: return "tv.fill"
        case .other: return "film"
        }
    }
}
```

## User Interface

### Quick Watch Toggle

Simple one-tap to mark as watched:

```swift
struct WatchToggleButton: View {
    let movie: Production
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button(action: toggleWatched) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: movie.watched ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(movie.watched ? Color.cageGold : .secondary)
                Text(movie.watched ? "Watched" : "Mark Watched")
            }
        }
    }

    private func toggleWatched() {
        if movie.watched {
            // Confirm before unmarking
            showUnwatchConfirmation = true
        } else {
            markAsWatched()
        }
    }

    private func markAsWatched() {
        movie.watched = true
        movie.dateWatched = Date()
        movie.watchCount += 1

        // Create basic watch event
        let event = WatchEvent(watchedDate: Date())
        event.production = movie
        movie.watchEvents.append(event)

        try? modelContext.save()
    }
}
```

### Detailed Watch Logger

For users who want to record more context:

```swift
struct WatchEventLogger: View {
    let movie: Production
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var watchDate = Date()
    @State private var location = ""
    @State private var notes = ""
    @State private var selectedMood: String?
    @State private var selectedFormat: WatchFormat?
    @State private var companions = ""

    let moods = ["😄 Great", "😊 Good", "😐 Okay", "😕 Meh", "😴 Tired"]

    var body: some View {
        NavigationStack {
            Form {
                // Date picker
                Section("When") {
                    DatePicker("Date Watched", selection: $watchDate, displayedComponents: [.date])
                }

                // Format
                Section("How") {
                    ForEach(WatchFormat.allCases, id: \.self) { format in
                        Button(action: { selectedFormat = format }) {
                            HStack {
                                Image(systemName: format.icon)
                                    .frame(width: 24)
                                Text(format.rawValue)
                                Spacer()
                                if selectedFormat == format {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.cageGold)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                // Location
                Section("Where") {
                    TextField("Location (optional)", text: $location)
                }

                // Companions
                Section("With Whom") {
                    TextField("Watched with... (optional)", text: $companions)
                }

                // Mood
                Section("Mood") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Spacing.sm) {
                            ForEach(moods, id: \.self) { mood in
                                MoodChip(mood: mood, isSelected: selectedMood == mood) {
                                    selectedMood = mood
                                }
                            }
                        }
                    }
                }

                // Notes
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Log Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveWatchEvent() }
                }
            }
        }
    }

    private func saveWatchEvent() {
        let event = WatchEvent(watchedDate: watchDate)
        event.location = location.isEmpty ? nil : location
        event.notes = notes.isEmpty ? nil : notes
        event.mood = selectedMood
        event.format = selectedFormat
        event.companions = companions.isEmpty ? nil : companions
        event.isRewatch = movie.watchCount > 0
        event.production = movie

        movie.watchEvents.append(event)
        movie.watched = true
        movie.dateWatched = watchDate
        movie.watchCount += 1

        try? modelContext.save()
        dismiss()
    }
}
```

### Watch History Section

Display watch history on movie detail:

```swift
struct WatchHistorySection: View {
    let movie: Production
    @State private var showAddEvent = false

    var sortedEvents: [WatchEvent] {
        movie.watchEvents.sorted { $0.watchedDate > $1.watchedDate }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text("Watch History")
                    .font(Typography.sectionHeader)

                Spacer()

                if movie.watched {
                    Button(action: { showAddEvent = true }) {
                        Image(systemName: "plus.circle")
                    }
                }
            }

            if sortedEvents.isEmpty {
                Text("No watch events recorded")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedEvents) { event in
                    WatchEventRow(event: event)
                }
            }

            // Watch count summary
            if movie.watchCount > 0 {
                HStack {
                    Image(systemName: "eye.fill")
                        .foregroundStyle(.secondary)
                    Text("Watched \(movie.watchCount) time\(movie.watchCount == 1 ? "" : "s")")
                        .font(Typography.caption1)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $showAddEvent) {
            WatchEventLogger(movie: movie)
        }
    }
}

struct WatchEventRow: View {
    let event: WatchEvent
    @State private var showDetail = false

    var body: some View {
        Button(action: { showDetail = true }) {
            HStack(spacing: Spacing.md) {
                // Date
                VStack(alignment: .center, spacing: 2) {
                    Text(event.watchedDate, format: .dateTime.day())
                        .font(Typography.title3)
                    Text(event.watchedDate, format: .dateTime.month(.abbreviated))
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                }
                .frame(width: 44)

                // Details
                VStack(alignment: .leading, spacing: Spacing.xxxs) {
                    HStack(spacing: Spacing.xs) {
                        if let format = event.format {
                            Image(systemName: format.icon)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        if event.isRewatch {
                            Text("Rewatch")
                                .font(Typography.caption2)
                                .foregroundStyle(Color.cageGold)
                        } else {
                            Text("First Watch")
                                .font(Typography.caption2)
                                .foregroundStyle(.green)
                        }
                    }

                    if let location = event.location {
                        Text(location)
                            .font(Typography.caption1)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                // Mood
                if let mood = event.mood {
                    Text(String(mood.prefix(2))) // Just the emoji
                        .font(.title3)
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(Spacing.sm)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            WatchEventDetail(event: event)
        }
    }
}
```

### Watch Event Detail

```swift
struct WatchEventDetail: View {
    let event: WatchEvent
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Date
                Section {
                    LabeledContent("Date", value: event.watchedDate, format: .dateTime)
                }

                // Format
                if let format = event.format {
                    Section {
                        LabeledContent("Watched via", value: format.rawValue)
                    }
                }

                // Location
                if let location = event.location {
                    Section("Location") {
                        Text(location)
                    }
                }

                // Companions
                if let companions = event.companions {
                    Section("Watched With") {
                        Text(companions)
                    }
                }

                // Mood
                if let mood = event.mood {
                    Section("Mood") {
                        Text(mood)
                    }
                }

                // Notes
                if let notes = event.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }

                // Metadata
                Section {
                    LabeledContent(event.isRewatch ? "Rewatch" : "First Watch", value: "")
                }
            }
            .navigationTitle("Watch Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
```

## Watchlist

### Adding to Watchlist

```swift
struct WatchlistButton: View {
    let movie: Production
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Button(action: toggleWatchlist) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: movie.onWatchlist ? "bookmark.fill" : "bookmark")
                    .foregroundStyle(movie.onWatchlist ? Color.cageGold : .secondary)
                Text(movie.onWatchlist ? "On Watchlist" : "Add to Watchlist")
            }
        }
    }

    private func toggleWatchlist() {
        movie.onWatchlist.toggle()
        movie.watchlistDate = movie.onWatchlist ? Date() : nil
        try? modelContext.save()
    }
}
```

### Watchlist View

```swift
struct WatchlistView: View {
    @Query(
        filter: #Predicate<Production> { $0.onWatchlist && !$0.watched },
        sort: \Production.watchlistDate,
        order: .reverse
    )
    private var watchlistMovies: [Production]

    @State private var sortOrder: WatchlistSort = .dateAdded

    var body: some View {
        NavigationStack {
            Group {
                if watchlistMovies.isEmpty {
                    EmptyStateView(
                        icon: "bookmark",
                        title: "Watchlist Empty",
                        message: "Add movies you want to watch to your watchlist.",
                        actionTitle: "Browse Movies"
                    ) {
                        // Navigate to browse
                    }
                } else {
                    List {
                        ForEach(sortedMovies) { movie in
                            WatchlistRow(movie: movie)
                        }
                        .onDelete(perform: removeFromWatchlist)
                    }
                }
            }
            .navigationTitle("Watchlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Sort", selection: $sortOrder) {
                            ForEach(WatchlistSort.allCases) { sort in
                                Text(sort.rawValue).tag(sort)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                    }
                }
            }
        }
    }

    private var sortedMovies: [Production] {
        switch sortOrder {
        case .dateAdded:
            return watchlistMovies.sorted { ($0.watchlistDate ?? .distantPast) > ($1.watchlistDate ?? .distantPast) }
        case .title:
            return watchlistMovies.sorted { $0.title < $1.title }
        case .releaseYear:
            return watchlistMovies.sorted { $0.releaseYear > $1.releaseYear }
        case .runtime:
            return watchlistMovies.sorted { ($0.runtime ?? 0) < ($1.runtime ?? 0) }
        }
    }

    private func removeFromWatchlist(at offsets: IndexSet) {
        for index in offsets {
            sortedMovies[index].onWatchlist = false
            sortedMovies[index].watchlistDate = nil
        }
    }
}

enum WatchlistSort: String, CaseIterable, Identifiable {
    case dateAdded = "Date Added"
    case title = "Title"
    case releaseYear = "Release Year"
    case runtime = "Runtime"

    var id: String { rawValue }
}
```

## Watch Statistics

### Overview Stats

```swift
struct WatchStats {
    let totalWatched: Int
    let totalUnwatched: Int
    let completionPercentage: Double
    let totalWatchEvents: Int
    let totalRewatches: Int
    let averageWatchesPerMovie: Double
    let favoriteFormat: WatchFormat?
    let mostActiveMonth: String?
    let currentStreak: Int
    let longestStreak: Int
}
```

### Stats Calculation

```swift
func calculateWatchStats(productions: [Production]) -> WatchStats {
    let watched = productions.filter { $0.watched }
    let unwatched = productions.filter { !$0.watched }

    let allEvents = watched.flatMap { $0.watchEvents }
    let rewatches = allEvents.filter { $0.isRewatch }.count

    // Format frequency
    let formatCounts = Dictionary(grouping: allEvents.compactMap { $0.format }) { $0 }
        .mapValues { $0.count }
    let favoriteFormat = formatCounts.max { $0.value < $1.value }?.key

    // Monthly activity
    let calendar = Calendar.current
    let monthCounts = Dictionary(grouping: allEvents) {
        calendar.dateComponents([.year, .month], from: $0.watchedDate)
    }.mapValues { $0.count }
    let topMonth = monthCounts.max { $0.value < $1.value }?.key
    let mostActiveMonth = topMonth.flatMap { components in
        guard let year = components.year, let month = components.month else { return nil }
        let date = calendar.date(from: components)!
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }

    return WatchStats(
        totalWatched: watched.count,
        totalUnwatched: unwatched.count,
        completionPercentage: Double(watched.count) / Double(productions.count),
        totalWatchEvents: allEvents.count,
        totalRewatches: rewatches,
        averageWatchesPerMovie: watched.isEmpty ? 0 : Double(allEvents.count) / Double(watched.count),
        favoriteFormat: favoriteFormat,
        mostActiveMonth: mostActiveMonth,
        currentStreak: calculateCurrentStreak(events: allEvents),
        longestStreak: calculateLongestStreak(events: allEvents)
    )
}
```

### Streak Calculation

```swift
func calculateCurrentStreak(events: [WatchEvent]) -> Int {
    let calendar = Calendar.current
    let sortedDates = Set(events.map {
        calendar.startOfDay(for: $0.watchedDate)
    }).sorted().reversed()

    guard let mostRecent = sortedDates.first else { return 0 }

    // Check if streak is still active (within last week)
    let today = calendar.startOfDay(for: Date())
    let daysSinceLast = calendar.dateComponents([.day], from: mostRecent, to: today).day ?? 0
    guard daysSinceLast <= 7 else { return 0 }

    var streak = 1
    var previousDate = mostRecent

    for date in sortedDates.dropFirst() {
        let daysBetween = calendar.dateComponents([.day], from: date, to: previousDate).day ?? 0
        if daysBetween <= 7 {
            streak += 1
            previousDate = date
        } else {
            break
        }
    }

    return streak
}
```

## Calendar View

Visualize watch history on a calendar:

```swift
struct WatchCalendarView: View {
    let events: [WatchEvent]
    @State private var selectedMonth = Date()

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                }

                Text(selectedMonth, format: .dateTime.month(.wide).year())
                    .font(Typography.title3)
                    .frame(maxWidth: .infinity)

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)

            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.xs) {
                // Weekday headers
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                }

                // Days
                ForEach(daysInMonth, id: \.self) { date in
                    DayCell(date: date, events: eventsForDate(date))
                }
            }
            .padding(.horizontal)
        }
    }

    private func eventsForDate(_ date: Date) -> [WatchEvent] {
        let calendar = Calendar.current
        return events.filter {
            calendar.isDate($0.watchedDate, inSameDayAs: date)
        }
    }

    // ... helper methods for calendar navigation
}

struct DayCell: View {
    let date: Date
    let events: [WatchEvent]

    var body: some View {
        ZStack {
            if !events.isEmpty {
                Circle()
                    .fill(Color.cageGold.opacity(0.3))
            }

            Text(date, format: .dateTime.day())
                .font(Typography.caption1)
                .foregroundStyle(events.isEmpty ? .primary : Color.cageGold)
        }
        .frame(height: 32)
    }
}
```

## Watch Reminders

### Reminder System

```swift
func scheduleWatchReminder(for movie: Production, at date: Date) {
    let content = UNMutableNotificationContent()
    content.title = "Movie Night!"
    content.body = "Don't forget to watch \(movie.title)"
    content.sound = .default

    let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
    let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

    let request = UNNotificationRequest(
        identifier: "watch_reminder_\(movie.id)",
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request)
}
```

## Import/Export

### Export Watch History

```swift
func exportWatchHistory() -> Data? {
    struct WatchExport: Codable {
        let movieTitle: String
        let movieYear: Int
        let tmdbID: Int?
        let events: [EventExport]
    }

    struct EventExport: Codable {
        let date: Date
        let location: String?
        let notes: String?
        let mood: String?
        let format: String?
    }

    let exports = productions.filter { $0.watched }.map { movie in
        WatchExport(
            movieTitle: movie.title,
            movieYear: movie.releaseYear,
            tmdbID: movie.tmdbID,
            events: movie.watchEvents.map { event in
                EventExport(
                    date: event.watchedDate,
                    location: event.location,
                    notes: event.notes,
                    mood: event.mood,
                    format: event.format?.rawValue
                )
            }
        )
    }

    return try? JSONEncoder().encode(exports)
}
```

## Accessibility

```swift
WatchToggleButton(movie: movie)
    .accessibilityLabel(movie.watched ? "Watched" : "Not watched")
    .accessibilityHint("Double tap to \(movie.watched ? "mark as unwatched" : "mark as watched")")
    .accessibilityAddTraits(.isButton)

WatchEventRow(event: event)
    .accessibilityLabel("Watched on \(event.watchedDate, format: .dateTime.month().day().year())")
    .accessibilityValue(event.isRewatch ? "Rewatch" : "First watch")
```

## Edge Cases

### Unmarking as Watched

```swift
.confirmationDialog(
    "Remove Watch Status?",
    isPresented: $showUnwatchConfirmation
) {
    Button("Keep Watch History", role: .cancel) {
        // Just toggle watched status, keep events
        movie.watched = false
    }

    Button("Remove All Watch Data", role: .destructive) {
        // Clear everything
        movie.watched = false
        movie.dateWatched = nil
        movie.watchCount = 0
        for event in movie.watchEvents {
            modelContext.delete(event)
        }
        movie.watchEvents.removeAll()
    }
} message: {
    Text("This movie has \(movie.watchEvents.count) watch events. What would you like to do?")
}
```

### Backdating Watches

Allow adding events for past dates:

```swift
DatePicker(
    "Date Watched",
    selection: $watchDate,
    in: ...Date(), // Only past and present
    displayedComponents: [.date]
)
```

## Future Enhancements

1. **Watch Parties**: Invite friends to watch together (virtual/in-person)
2. **Location History**: Map of where you've watched movies
3. **Photo Memories**: Attach photos to watch events
4. **Apple Calendar Integration**: Sync with calendar app
5. **Siri Shortcuts**: "Hey Siri, I just watched Face/Off"
6. **Watch Predictions**: ML-based suggestions for what to watch next
7. **Mood Tracking Analytics**: Insights about viewing moods over time
