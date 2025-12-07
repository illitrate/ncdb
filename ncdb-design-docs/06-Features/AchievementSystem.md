# NCDB Achievement System

## Overview

The achievement system gamifies the Nicolas Cage movie-watching experience, rewarding users for milestones and encouraging engagement with the app. Achievements provide a sense of progress and accomplishment while adding a fun, collectible aspect to movie tracking.

## Design Philosophy

1. **Celebrate Progress**: Every achievement should feel like a genuine accomplishment
2. **Encourage Exploration**: Achievements guide users to discover app features
3. **Avoid Pressure**: Never punish users or make them feel bad for not achieving
4. **Delightful Surprises**: Some achievements are hidden until unlocked
5. **Shareable**: Achievements are designed to be shared on social media

## Achievement Structure

### Achievement Model

```swift
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String           // SF Symbol name
    let points: Int
    let category: AchievementCategory
    let rarity: AchievementRarity
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: AchievementProgress?
    var isHidden: Bool         // Hidden until unlocked
}

struct AchievementProgress: Codable {
    let current: Double
    let target: Double

    var percentage: Double {
        min(current / target, 1.0)
    }

    var remainingText: String {
        let remaining = Int(target - current)
        return "\(remaining) more to go"
    }
}
```

### Categories

```swift
enum AchievementCategory: String, CaseIterable, Codable {
    case watching = "Watching"     // Movie watching milestones
    case rating = "Rating"         // Rating and reviewing
    case collecting = "Collecting" // Favorites, tags, lists
    case exploring = "Exploring"   // App feature discovery
    case social = "Social"         // Sharing and community

    var icon: String {
        switch self {
        case .watching: return "eye.fill"
        case .rating: return "star.fill"
        case .collecting: return "folder.fill"
        case .exploring: return "globe"
        case .social: return "person.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .watching: return .blue
        case .rating: return .yellow
        case .collecting: return .purple
        case .exploring: return .green
        case .social: return .orange
        }
    }
}
```

### Rarity Levels

```swift
enum AchievementRarity: String, Codable {
    case common = "Common"         // Easy to obtain
    case uncommon = "Uncommon"     // Moderate effort
    case rare = "Rare"             // Significant commitment
    case epic = "Epic"             // Major milestone
    case legendary = "Legendary"   // Ultimate achievement

    var stars: Int {
        switch self {
        case .common: return 1
        case .uncommon: return 2
        case .rare: return 3
        case .epic: return 4
        case .legendary: return 5
        }
    }

    var pointMultiplier: Double {
        switch self {
        case .common: return 1.0
        case .uncommon: return 1.5
        case .rare: return 2.0
        case .epic: return 3.0
        case .legendary: return 5.0
        }
    }
}
```

## Achievement Catalog

### Watching Category

| ID | Title | Description | Target | Points | Rarity |
|----|-------|-------------|--------|--------|--------|
| `first_watch` | First Steps | Watch your first Nicolas Cage movie | 1 | 10 | Common |
| `getting_started` | Getting Started | Watch 5 movies | 5 | 25 | Common |
| `cage_enthusiast` | Cage Enthusiast | Watch 10 movies | 10 | 50 | Uncommon |
| `cage_fan` | Dedicated Fan | Watch 25 movies | 25 | 100 | Rare |
| `cage_devotee` | Cage Devotee | Watch 50 movies | 50 | 250 | Epic |
| `cage_master` | Cage Master | Watch 75 movies | 75 | 500 | Epic |
| `one_true_god` | One True God | Watch every Nicolas Cage movie | All | 1000 | Legendary |
| `decade_explorer` | Decade Explorer | Watch movies from 5 different decades | 5 | 75 | Uncommon |
| `genre_variety` | Genre Variety | Watch movies from 10 different genres | 10 | 100 | Rare |
| `marathon_runner` | Marathon Runner | Watch 5 movies in one week | 5/week | 50 | Uncommon |
| `binge_master` | Binge Master | Watch 3 movies in one day | 3/day | 75 | Rare |

### Rating Category

| ID | Title | Description | Target | Points | Rarity |
|----|-------|-------------|--------|--------|--------|
| `first_rating` | Film Critic | Rate your first movie | 1 | 10 | Common |
| `opinionated` | Opinionated | Rate 10 movies | 10 | 50 | Uncommon |
| `rating_enthusiast` | Rating Enthusiast | Rate 25 movies | 25 | 100 | Rare |
| `professional_critic` | Professional Critic | Rate 50 movies | 50 | 200 | Epic |
| `first_review` | First Thoughts | Write your first review | 1 | 15 | Common |
| `reviewer` | Reviewer | Write 10 reviews | 10 | 75 | Uncommon |
| `literary_critic` | Literary Critic | Write 25 reviews | 25 | 150 | Rare |
| `five_star_fan` | Five Star Fan | Give 10 movies a 5-star rating | 10 | 50 | Uncommon |
| `tough_critic` | Tough Critic | Give 5 movies a 1-star rating | 5 | 50 | Uncommon |

### Collecting Category

| ID | Title | Description | Target | Points | Rarity |
|----|-------|-------------|--------|--------|--------|
| `first_favorite` | Heart of Gold | Add your first favorite | 1 | 10 | Common |
| `collector` | Collector | Add 5 favorites | 5 | 50 | Uncommon |
| `curator` | Curator | Add 10 favorites | 10 | 100 | Rare |
| `first_tag` | Tag Master | Create your first custom tag | 1 | 15 | Common |
| `organized` | Organized | Create 5 custom tags | 5 | 50 | Uncommon |
| `first_ranking` | Ranked | Add your first movie to ranking | 1 | 15 | Common |
| `ranking_started` | Top 10 | Rank 10 movies | 10 | 50 | Uncommon |
| `ranking_master` | Ranking Master | Rank 25 movies | 25 | 100 | Rare |

### Exploring Category

| ID | Title | Description | Target | Points | Rarity |
|----|-------|-------------|--------|--------|--------|
| `stats_viewed` | Numbers Person | View your statistics | 1 | 10 | Common |
| `widget_user` | Widget Enthusiast | Add a home screen widget | 1 | 25 | Uncommon |
| `news_reader` | News Reader | Read 10 Cage news articles | 10 | 50 | Uncommon |
| `search_master` | Search Master | Use advanced search filters | 1 | 15 | Common |
| `theme_changer` | Personalized | Change app theme/appearance | 1 | 10 | Common |

### Social Category

| ID | Title | Description | Target | Points | Rarity |
|----|-------|-------------|--------|--------|--------|
| `first_share` | Sharing is Caring | Share your first movie | 1 | 15 | Common |
| `social_butterfly` | Social Butterfly | Share 10 times | 10 | 75 | Uncommon |
| `ranking_shared` | Proud Ranker | Share your ranking | 1 | 25 | Common |
| `achievement_shared` | Show Off | Share an achievement | 1 | 15 | Common |

### Hidden Achievements

| ID | Title | Description | Trigger | Points | Rarity |
|----|-------|-------------|---------|--------|--------|
| `night_owl` | Night Owl | Log a watch event after midnight | Time-based | 25 | Common |
| `early_bird` | Early Bird | Log a watch event before 6 AM | Time-based | 25 | Common |
| `face_off_fan` | Face/Off Fan | Watch Face/Off 3 times | Specific movie | 50 | Rare |
| `national_treasure` | National Treasure | Watch both National Treasure movies | Specific movies | 50 | Uncommon |
| `gone_classic` | Gone Classic | Watch every movie from the 1980s | Decade complete | 100 | Rare |
| `new_millennium` | New Millennium | Watch every movie from the 2000s | Decade complete | 100 | Rare |
| `action_hero` | Action Hero | Watch 20 action movies | Genre-specific | 75 | Uncommon |
| `comedy_gold` | Comedy Gold | Watch 15 comedy movies | Genre-specific | 75 | Uncommon |

## Achievement Engine

### Achievement Manager

```swift
@Observable
@MainActor
final class AchievementManager {
    static let shared = AchievementManager()

    private(set) var achievements: [Achievement] = []
    private(set) var recentlyUnlocked: [Achievement] = []

    private var modelContext: ModelContext?

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadAchievements()
    }

    // MARK: - Achievement Checking

    func checkAchievements() async {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<Production>()
        guard let productions = try? modelContext.fetch(descriptor) else { return }

        let watchedCount = productions.filter { $0.watched }.count
        let ratedCount = productions.filter { $0.userRating != nil }.count
        let reviewCount = productions.filter { $0.review != nil }.count
        let favoriteCount = productions.filter { $0.isFavorite }.count
        let rankedCount = productions.filter { $0.rankingPosition != nil }.count

        // Check each achievement
        await checkWatchingAchievements(watchedCount: watchedCount, productions: productions)
        await checkRatingAchievements(ratedCount: ratedCount, reviewCount: reviewCount)
        await checkCollectingAchievements(favoriteCount: favoriteCount, rankedCount: rankedCount)
    }

    private func checkWatchingAchievements(watchedCount: Int, productions: [Production]) async {
        // First watch
        await checkAndUnlock("first_watch", condition: watchedCount >= 1)

        // Milestone achievements
        await checkAndUnlock("getting_started", condition: watchedCount >= 5)
        await checkAndUnlock("cage_enthusiast", condition: watchedCount >= 10)
        await checkAndUnlock("cage_fan", condition: watchedCount >= 25)
        await checkAndUnlock("cage_devotee", condition: watchedCount >= 50)
        await checkAndUnlock("cage_master", condition: watchedCount >= 75)

        // Complete collection
        let totalMovies = productions.count
        await checkAndUnlock("one_true_god", condition: watchedCount >= totalMovies && totalMovies > 0)

        // Decade explorer
        let decades = Set(productions.filter { $0.watched }.map { ($0.releaseYear / 10) * 10 })
        await checkAndUnlock("decade_explorer", condition: decades.count >= 5)

        // Genre variety
        let genres = Set(productions.filter { $0.watched }.flatMap { $0.genres })
        await checkAndUnlock("genre_variety", condition: genres.count >= 10)
    }

    private func checkRatingAchievements(ratedCount: Int, reviewCount: Int) async {
        await checkAndUnlock("first_rating", condition: ratedCount >= 1)
        await checkAndUnlock("opinionated", condition: ratedCount >= 10)
        await checkAndUnlock("rating_enthusiast", condition: ratedCount >= 25)
        await checkAndUnlock("professional_critic", condition: ratedCount >= 50)

        await checkAndUnlock("first_review", condition: reviewCount >= 1)
        await checkAndUnlock("reviewer", condition: reviewCount >= 10)
        await checkAndUnlock("literary_critic", condition: reviewCount >= 25)
    }

    private func checkCollectingAchievements(favoriteCount: Int, rankedCount: Int) async {
        await checkAndUnlock("first_favorite", condition: favoriteCount >= 1)
        await checkAndUnlock("collector", condition: favoriteCount >= 5)
        await checkAndUnlock("curator", condition: favoriteCount >= 10)

        await checkAndUnlock("first_ranking", condition: rankedCount >= 1)
        await checkAndUnlock("ranking_started", condition: rankedCount >= 10)
        await checkAndUnlock("ranking_master", condition: rankedCount >= 25)
    }

    // MARK: - Unlock Logic

    private func checkAndUnlock(_ achievementID: String, condition: Bool) async {
        guard condition else { return }
        guard let index = achievements.firstIndex(where: { $0.id == achievementID }) else { return }
        guard !achievements[index].isUnlocked else { return }

        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()

        recentlyUnlocked.append(achievements[index])
        saveAchievements()

        // Post notification for UI to show celebration
        NotificationCenter.default.post(
            name: .achievementUnlocked,
            object: achievements[index]
        )
    }

    // MARK: - Persistence

    private func loadAchievements() {
        // Load from UserDefaults or initialize defaults
        if let data = UserDefaults.standard.data(forKey: "achievements"),
           let saved = try? JSONDecoder().decode([Achievement].self, from: data) {
            achievements = saved
        } else {
            achievements = AchievementCatalog.all
        }
    }

    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(data, forKey: "achievements")
        }
    }

    // MARK: - Stats

    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var totalCount: Int {
        achievements.filter { !$0.isHidden || $0.isUnlocked }.count
    }

    var totalPoints: Int {
        achievements.filter { $0.isUnlocked }.reduce(0) { $0 + $1.points }
    }

    var completionPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }
}
```

### Achievement Catalog

```swift
enum AchievementCatalog {
    static let all: [Achievement] = [
        // Watching
        Achievement(
            id: "first_watch",
            title: "First Steps",
            description: "Watch your first Nicolas Cage movie",
            icon: "play.fill",
            points: 10,
            category: .watching,
            rarity: .common,
            isUnlocked: false,
            isHidden: false
        ),
        Achievement(
            id: "cage_enthusiast",
            title: "Cage Enthusiast",
            description: "Watch 10 Nicolas Cage movies",
            icon: "film.fill",
            points: 50,
            category: .watching,
            rarity: .uncommon,
            isUnlocked: false,
            isHidden: false
        ),
        Achievement(
            id: "one_true_god",
            title: "One True God",
            description: "Watch every Nicolas Cage movie",
            icon: "sparkles",
            points: 1000,
            category: .watching,
            rarity: .legendary,
            isUnlocked: false,
            isHidden: false
        ),
        // ... more achievements
    ]
}
```

## Unlock Celebration

### Visual Celebration

When an achievement is unlocked, show a full-screen celebration:

```swift
struct AchievementUnlockCelebration: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var showConfetti = true

    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Confetti
            if showConfetti {
                ConfettiView()
            }

            // Achievement content
            VStack(spacing: Spacing.xl) {
                Text("Achievement Unlocked!")
                    .font(Typography.title1)
                    .foregroundStyle(Color.cageGold)

                // Icon with glow effect
                ZStack {
                    // Pulsing glow rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.cageGold.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                            .frame(width: 140 + CGFloat(i * 20))
                            .scaleEffect(scale)
                    }

                    Circle()
                        .fill(LinearGradient(
                            colors: [.cageGold, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 120, height: 120)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }
                .scaleEffect(scale)

                VStack(spacing: Spacing.sm) {
                    Text(achievement.title)
                        .font(Typography.title2)

                    Text("+\(achievement.points) Points")
                        .font(Typography.bodyBold)
                        .foregroundStyle(Color.cageGold)
                }

                Button("Awesome!") {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.cageGold)
            }
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            // Auto-dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                withAnimation { showConfetti = false }
            }
        }
    }
}
```

### Haptic Feedback

```swift
func playUnlockHaptics() {
    let generator = UINotificationFeedbackGenerator()
    generator.notificationOccurred(.success)

    // Additional celebration haptics
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
}
```

### Sound Effect

```swift
func playUnlockSound() {
    // Play system sound or custom audio
    AudioServicesPlaySystemSound(1025) // System "unlock" sound
}
```

## Progress Tracking

### Progress Updates

```swift
func updateProgress(for achievementID: String, current: Double, target: Double) {
    guard let index = achievements.firstIndex(where: { $0.id == achievementID }) else { return }
    guard !achievements[index].isUnlocked else { return }

    achievements[index].progress = AchievementProgress(current: current, target: target)

    if current >= target {
        Task {
            await checkAndUnlock(achievementID, condition: true)
        }
    }
}
```

### Progress Display

```swift
struct AchievementProgressView: View {
    let achievement: Achievement

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack {
                Text(achievement.title)
                    .font(Typography.bodyBold)
                Spacer()
                if let progress = achievement.progress {
                    Text("\(Int(progress.current))/\(Int(progress.target))")
                        .font(Typography.caption1)
                        .foregroundStyle(.secondary)
                }
            }

            if let progress = achievement.progress {
                ProgressView(value: progress.current, total: progress.target)
                    .tint(Color.cageGold)
            }
        }
    }
}
```

## Notifications

### Local Notifications

```swift
func scheduleAchievementReminder() {
    let content = UNMutableNotificationContent()
    content.title = "Achievement Progress"
    content.body = "You're close to unlocking 'Cage Enthusiast'! Watch 2 more movies."
    content.sound = .default

    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 86400, repeats: false)
    let request = UNNotificationRequest(
        identifier: "achievement_reminder",
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request)
}
```

### In-App Notifications

```swift
extension Notification.Name {
    static let achievementUnlocked = Notification.Name("achievementUnlocked")
    static let achievementProgress = Notification.Name("achievementProgress")
}

// Observe in main view
.onReceive(NotificationCenter.default.publisher(for: .achievementUnlocked)) { notification in
    if let achievement = notification.object as? Achievement {
        showUnlockCelebration(achievement)
    }
}
```

## Sharing Achievements

### Share Content

```swift
func generateShareContent(for achievement: Achievement) -> String {
    """
    🏆 Achievement Unlocked!

    \(achievement.title)
    \(achievement.description)

    +\(achievement.points) points

    #NicolasCage #NCDB
    """
}
```

### Share Image

```swift
struct AchievementShareImage: View {
    let achievement: Achievement

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Achievement badge
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.cageGold, .orange],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)

                Image(systemName: achievement.icon)
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }

            Text(achievement.title)
                .font(.title2.bold())

            Text(achievement.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Rarity stars
            HStack {
                ForEach(0..<achievement.rarity.stars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundStyle(Color.cageGold)
                }
            }

            Text("NCDB - Nicolas Cage Database")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.xl)
        .background(Color.primaryBackground)
    }
}
```

## Points System

### Point Values

| Rarity | Base Points | With Multiplier |
|--------|-------------|-----------------|
| Common | 10 | 10 |
| Uncommon | 25-50 | 37-75 |
| Rare | 75-100 | 150-200 |
| Epic | 200-500 | 600-1500 |
| Legendary | 1000 | 5000 |

### Leaderboard (Future)

```swift
struct LeaderboardEntry: Identifiable {
    let id: String
    let username: String
    let totalPoints: Int
    let achievementCount: Int
    let rank: Int
}
```

## Testing

### Test Helpers

```swift
#if DEBUG
extension AchievementManager {
    func unlockAllAchievements() {
        for i in achievements.indices {
            achievements[i].isUnlocked = true
            achievements[i].unlockedDate = Date()
        }
        saveAchievements()
    }

    func resetAllAchievements() {
        achievements = AchievementCatalog.all
        saveAchievements()
    }

    func unlockAchievement(_ id: String) {
        Task {
            await checkAndUnlock(id, condition: true)
        }
    }
}
#endif
```

## Future Enhancements

1. **Seasonal Achievements**: Time-limited achievements for holidays
2. **Streak Achievements**: Rewards for consistent daily/weekly activity
3. **Secret Achievements**: Easter eggs for specific actions
4. **Achievement Tiers**: Bronze/Silver/Gold versions of same achievement
5. **Friend Comparisons**: See which achievements friends have unlocked
6. **Achievement Recommendations**: Suggest next achievements to pursue
