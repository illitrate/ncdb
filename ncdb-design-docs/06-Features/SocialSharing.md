# NCDB Social Sharing System

## Overview

The social sharing system enables users to share their Nicolas Cage movie experiences across platforms. It's designed to create engaging, visually appealing content that represents the NCDB brand while celebrating users' Cage fandom.

## Core Concepts

### Sharing Philosophy

1. **Celebrate the Fan**: Make users feel proud of their Cage journey
2. **Brand Presence**: Every share subtly promotes NCDB
3. **Visual Appeal**: Beautiful, shareable graphics that stand out
4. **Platform Optimization**: Tailored content for each social platform
5. **Easy Access**: Share from anywhere in the app with minimal friction

## Shareable Content Types

### 1. Movie Rating/Review

Share individual movie ratings and reviews:

```swift
struct MovieShareContent {
    let movie: Production
    let rating: Double?
    let review: String?
    let character: String? // Cage's character

    func generateText() -> String {
        var text = "\(movie.title) (\(movie.releaseYear))"

        if let rating {
            text += "\nP \(String(format: "%.1f", rating))/5"
        }

        if let character {
            text += "\nNicolas Cage as \(character)"
        }

        if let review, !review.isEmpty {
            text += "\n\n\"\(review)\""
        }

        text += "\n\n#NicolasCage #NCDB"
        return text
    }

    var tmdbURL: URL? {
        guard let tmdbID = movie.tmdbID else { return nil }
        return URL(string: "https://www.themoviedb.org/movie/\(tmdbID)")
    }
}
```

### 2. Ranking

Share personal rankings:

```swift
struct RankingShareContent {
    let movies: [Production]
    let title: String
    let topN: Int? // Limit to top N

    func generateText() -> String {
        let moviesToShare = topN.map { Array(movies.prefix($0)) } ?? movies

        var text = "<¬ \(title)\n\n"

        for (index, movie) in moviesToShare.enumerated() {
            let medal = medalEmoji(for: index)
            let rating = movie.userRating.map { " P \(String(format: "%.1f", $0))" } ?? ""
            text += "\(medal) #\(index + 1) \(movie.title) (\(movie.releaseYear))\(rating)\n"
        }

        text += "\n#NicolasCage #NCDB"
        return text
    }

    private func medalEmoji(for index: Int) -> String {
        switch index {
        case 0: return ">G"
        case 1: return ">H"
        case 2: return ">I"
        default: return "  "
        }
    }
}
```

### 3. Statistics

Share viewing statistics:

```swift
struct StatsShareContent {
    let stats: OverviewStats
    let insights: [StatInsight]

    func generateText() -> String {
        """
        <¬ My Nicolas Cage Stats

        =Ê Overview
        " Watched: \(stats.watchedCount) of \(stats.totalMovies) movies
        " Completion: \(stats.formattedCompletion)
        " Average Rating: \(stats.formattedAverageRating) P

        ñ Time Spent
        " Total: \(stats.formattedRuntime)

        <Æ Highlights
        \(insights.prefix(3).map { "" \($0.title): \($0.value)" }.joined(separator: "\n"))

        #NicolasCage #NCDB
        """
    }
}
```

### 4. Achievements

Share unlocked achievements:

```swift
struct AchievementShareContent {
    let achievement: Achievement

    func generateText() -> String {
        """
        <Æ Achievement Unlocked!

        \(achievement.title)
        \(achievement.description)

        +\(achievement.points) points

        #NicolasCage #NCDB
        """
    }
}
```

### 5. Watch Milestone

Share viewing milestones:

```swift
struct MilestoneShareContent {
    let milestoneType: MilestoneType
    let movie: Production?
    let count: Int

    enum MilestoneType {
        case firstWatch
        case tenthWatch
        case twentyFifthWatch
        case fiftiethWatch
        case hundredthWatch
        case complete
    }

    func generateText() -> String {
        switch milestoneType {
        case .firstWatch:
            return "<¬ Started my Nicolas Cage journey with \(movie?.title ?? "")!\n\n#NicolasCage #NCDB"
        case .tenthWatch:
            return "<¬ Just watched my 10th Nicolas Cage movie: \(movie?.title ?? "")!\n\n#NicolasCage #NCDB"
        case .complete:
            return "<Æ I've watched EVERY Nicolas Cage movie! (\(count) films)\n\nOne True God achieved!\n\n#NicolasCage #NCDB"
        default:
            return "<¬ Milestone: \(count) Nicolas Cage movies watched!\n\n#NicolasCage #NCDB"
        }
    }
}
```

## Share Images

### Image Generator

Generate branded images for sharing:

```swift
struct ShareImageGenerator {

    // MARK: - Movie Card

    func generateMovieCard(movie: Production, rating: Double?) -> UIImage? {
        let view = MovieShareCard(movie: movie, rating: rating)
        return renderToImage(view: view, size: CGSize(width: 600, height: 800))
    }

    // MARK: - Ranking Card

    func generateRankingCard(movies: [Production], title: String) -> UIImage? {
        let view = RankingShareCard(movies: Array(movies.prefix(10)), title: title)
        return renderToImage(view: view, size: CGSize(width: 600, height: 900))
    }

    // MARK: - Stats Card

    func generateStatsCard(stats: OverviewStats) -> UIImage? {
        let view = StatsShareCard(stats: stats)
        return renderToImage(view: view, size: CGSize(width: 600, height: 600))
    }

    // MARK: - Achievement Card

    func generateAchievementCard(achievement: Achievement) -> UIImage? {
        let view = AchievementShareCard(achievement: achievement)
        return renderToImage(view: view, size: CGSize(width: 600, height: 600))
    }

    // MARK: - Render Helper

    private func renderToImage<V: View>(view: V, size: CGSize) -> UIImage? {
        let controller = UIHostingController(rootView: view)
        controller.view.frame = CGRect(origin: .zero, size: size)

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
}
```

### Movie Share Card

```swift
struct MovieShareCard: View {
    let movie: Production
    let rating: Double?

    var body: some View {
        VStack(spacing: 0) {
            // Poster area
            ZStack(alignment: .bottom) {
                // Poster image
                AsyncImage(url: posterURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.secondaryBackground)
                }
                .frame(height: 450)
                .clipped()

                // Gradient overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.8)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
            }

            // Info area
            VStack(spacing: Spacing.md) {
                Text(movie.title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(String(movie.releaseYear))
                    .font(.headline)
                    .foregroundStyle(.secondary)

                if let rating {
                    HStack(spacing: 4) {
                        ForEach(0..<5) { index in
                            Image(systemName: index < Int(rating) ? "star.fill" : "star")
                                .foregroundStyle(Color.cageGold)
                        }
                    }
                    .font(.title2)
                }

                // Branding
                HStack {
                    Image("ncdb-logo")
                        .resizable()
                        .frame(width: 24, height: 24)
                    Text("NCDB")
                        .font(.caption.bold())
                }
                .foregroundStyle(.secondary)
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .background(Color.primaryBackground)
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var posterURL: URL? {
        guard let path = movie.posterPath else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/w500\(path)")
    }
}
```

### Ranking Share Card

```swift
struct RankingShareCard: View {
    let movies: [Production]
    let title: String

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Header
            VStack(spacing: Spacing.xs) {
                Image(systemName: "trophy.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.cageGold)

                Text(title)
                    .font(.title2.bold())
            }
            .padding(.top, Spacing.xl)

            // Ranking list
            VStack(spacing: Spacing.sm) {
                ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
                    HStack {
                        Text("#\(index + 1)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(index < 3 ? Color.cageGold : .secondary)
                            .frame(width: 40, alignment: .leading)

                        Text(movie.title)
                            .font(.body)
                            .lineLimit(1)

                        Spacer()

                        Text("(\(movie.releaseYear))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, Spacing.lg)
                }
            }

            Spacer()

            // Branding
            HStack {
                Image("ncdb-logo")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("Generated with NCDB")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .padding(.bottom, Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
    }
}
```

### Stats Share Card

```swift
struct StatsShareCard: View {
    let stats: OverviewStats

    var body: some View {
        VStack(spacing: Spacing.xl) {
            // Header
            VStack(spacing: Spacing.sm) {
                Image(systemName: "chart.bar.fill")
                    .font(.largeTitle)
                    .foregroundStyle(Color.cageGold)

                Text("My Cage Stats")
                    .font(.title2.bold())
            }

            // Stats grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Spacing.lg) {
                StatBox(title: "Movies Watched", value: "\(stats.watchedCount)")
                StatBox(title: "Completion", value: stats.formattedCompletion)
                StatBox(title: "Avg Rating", value: stats.formattedAverageRating)
                StatBox(title: "Time Spent", value: stats.formattedRuntime)
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            // Branding
            HStack {
                Image("ncdb-logo")
                    .resizable()
                    .frame(width: 20, height: 20)
                Text("NCDB - Nicolas Cage Database")
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
    }
}

struct StatBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: Spacing.xs) {
            Text(value)
                .font(.title.bold())
                .foregroundStyle(Color.cageGold)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
```

## Share Sheet Integration

### Universal Share Button

```swift
struct ShareButton<Content: ShareableContent>: View {
    let content: Content
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?
    @State private var isGeneratingImage = false

    var body: some View {
        Menu {
            // Share as text
            ShareLink(item: content.shareText) {
                Label("Share as Text", systemImage: "text.quote")
            }

            // Share as image
            Button(action: generateAndShareImage) {
                Label("Share as Image", systemImage: "photo")
            }

            // Copy to clipboard
            Button(action: copyToClipboard) {
                Label("Copy Text", systemImage: "doc.on.doc")
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    private func generateAndShareImage() {
        isGeneratingImage = true
        Task {
            shareImage = await content.generateShareImage()
            isGeneratingImage = false
            showShareSheet = true
        }
    }

    private func copyToClipboard() {
        UIPasteboard.general.string = content.shareText
        // Show confirmation toast
    }
}
```

### ShareSheet Wrapper

```swift
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var excludedActivityTypes: [UIActivity.ActivityType]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        controller.excludedActivityTypes = excludedActivityTypes
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
```

## Platform-Specific Optimization

### Twitter/X

```swift
struct TwitterOptimizedContent {
    static let maxLength = 280

    static func format(_ content: String) -> String {
        var text = content

        // Shorten if needed
        if text.count > maxLength {
            let hashtags = "\n\n#NicolasCage #NCDB"
            let availableLength = maxLength - hashtags.count - 3 // for "..."
            text = String(text.prefix(availableLength)) + "..." + hashtags
        }

        return text
    }
}
```

### Instagram

For Instagram, focus on images:

```swift
struct InstagramShareContent {
    let image: UIImage
    let caption: String

    // Instagram requires saving to camera roll first
    func prepareForInstagram() {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        UIPasteboard.general.string = caption
        // Show instructions to paste caption
    }
}
```

### Stories

Vertical format for Instagram/Snapchat stories:

```swift
struct StoryShareCard: View {
    let movie: Production
    let rating: Double?

    var body: some View {
        ZStack {
            // Full-bleed poster
            AsyncImage(url: posterURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.secondaryBackground
            }

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.9)],
                startPoint: .center,
                endPoint: .bottom
            )

            // Content
            VStack {
                Spacer()

                VStack(spacing: Spacing.md) {
                    Text(movie.title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)

                    if let rating {
                        StarRatingView(rating: rating, style: .large)
                    }

                    // NCDB branding
                    HStack {
                        Image("ncdb-logo")
                            .resizable()
                            .frame(width: 30, height: 30)
                        Text("@ncdb.app")
                            .font(.caption.bold())
                    }
                    .foregroundStyle(.white.opacity(0.8))
                }
                .padding(.bottom, 80) // Safe area for story UI
            }
        }
        .frame(width: 1080, height: 1920) // Story dimensions
    }
}
```

## Deep Links

### Share Links

```swift
struct NCDBDeepLink {
    static let scheme = "ncdb"
    static let host = "app"

    enum Route {
        case movie(id: UUID)
        case ranking
        case stats
        case achievement(id: String)

        var url: URL? {
            switch self {
            case .movie(let id):
                return URL(string: "\(scheme)://\(host)/movie/\(id.uuidString)")
            case .ranking:
                return URL(string: "\(scheme)://\(host)/ranking")
            case .stats:
                return URL(string: "\(scheme)://\(host)/stats")
            case .achievement(let id):
                return URL(string: "\(scheme)://\(host)/achievement/\(id)")
            }
        }
    }
}
```

### Universal Links

For web fallback:

```swift
// apple-app-site-association
{
    "applinks": {
        "apps": [],
        "details": [
            {
                "appID": "TEAM_ID.com.ncdb.app",
                "paths": [
                    "/movie/*",
                    "/ranking/*",
                    "/stats",
                    "/achievement/*"
                ]
            }
        ]
    }
}
```

## Share Analytics

Track sharing behavior (privacy-respecting):

```swift
struct ShareAnalytics {
    enum ShareType: String {
        case movie
        case ranking
        case stats
        case achievement
        case milestone
    }

    enum ShareMethod: String {
        case text
        case image
        case copy
    }

    static func log(type: ShareType, method: ShareMethod, platform: String? = nil) {
        // Log to analytics (respecting user privacy preferences)
        let event = [
            "type": type.rawValue,
            "method": method.rawValue,
            "platform": platform ?? "unknown"
        ]
        // Send to analytics service
    }
}
```

## Share Triggers

### Automatic Prompts

Suggest sharing at key moments:

```swift
struct SharePromptManager {

    func shouldPromptShare(after event: AppEvent) -> SharePrompt? {
        switch event {
        case .achievementUnlocked(let achievement):
            if achievement.rarity >= .rare {
                return SharePrompt(
                    title: "Share Your Achievement?",
                    message: "You unlocked a rare achievement!",
                    content: .achievement(achievement)
                )
            }

        case .milestoneReached(let milestone):
            return SharePrompt(
                title: "Celebrate Your Milestone!",
                message: "Share your progress with friends",
                content: .milestone(milestone)
            )

        case .collectionComplete:
            return SharePrompt(
                title: "You Did It!",
                message: "You've watched every Nicolas Cage movie!",
                content: .milestone(.complete)
            )

        default:
            return nil
        }
        return nil
    }
}

struct SharePrompt {
    let title: String
    let message: String
    let content: ShareableContent
}
```

## Accessibility

```swift
ShareButton(content: movieContent)
    .accessibilityLabel("Share \(movie.title)")
    .accessibilityHint("Opens share menu with options to share as text or image")
```

## Privacy Considerations

### User Consent

```swift
struct SharePrivacySettings {
    /// Include username in shares
    var includeUsername: Bool = false

    /// Include watch date in shares
    var includeWatchDate: Bool = true

    /// Include location in shares
    var includeLocation: Bool = false

    /// Include personal notes in shares
    var includeNotes: Bool = false
}
```

### Content Filtering

```swift
func sanitizeForSharing(_ content: String) -> String {
    // Remove any personal information that shouldn't be shared
    var sanitized = content

    // Remove email addresses
    let emailPattern = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    if let regex = try? NSRegularExpression(pattern: emailPattern) {
        sanitized = regex.stringByReplacingMatches(
            in: sanitized,
            range: NSRange(sanitized.startIndex..., in: sanitized),
            withTemplate: "[email]"
        )
    }

    return sanitized
}
```

## Error Handling

```swift
enum ShareError: LocalizedError {
    case imageGenerationFailed
    case noContentToShare
    case platformUnavailable

    var errorDescription: String? {
        switch self {
        case .imageGenerationFailed:
            return "Couldn't generate share image"
        case .noContentToShare:
            return "No content available to share"
        case .platformUnavailable:
            return "This sharing option isn't available"
        }
    }
}
```

## Future Enhancements

1. **Social Profiles**: Connect social accounts for one-tap sharing
2. **Share Templates**: User-customizable share templates
3. **Scheduled Shares**: Schedule shares for optimal times
4. **Share History**: Track what you've shared
5. **Collaborative Lists**: Share rankings with friends for voting
6. **QR Codes**: Generate QR codes linking to shared content
7. **Widget Sharing**: Share directly from home screen widgets
8. **Siri Integration**: "Hey Siri, share my Cage ranking"
