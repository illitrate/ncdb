// NCDB Achievement Views
// Gamification and progress tracking UI components

import SwiftUI
import SwiftData

// MARK: - Achievements Main View

/// Main view displaying all achievements and progress
///
/// Features:
/// - Achievement categories with progress
/// - Unlocked vs locked achievement display
/// - Progress bars and statistics
/// - Celebratory animations for unlocks
/// - Share achievements functionality
struct AchievementsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AchievementsViewModel()
    @State private var selectedCategory: AchievementCategory = .watching
    @State private var showUnlockedOnly = false
    @Namespace private var animation

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Overall progress header
                    OverallProgressHeader(
                        unlockedCount: viewModel.unlockedCount,
                        totalCount: viewModel.totalCount,
                        points: viewModel.totalPoints
                    )

                    // Category filter
                    CategoryFilterBar(
                        categories: AchievementCategory.allCases,
                        selected: $selectedCategory
                    )

                    // Toggle for unlocked only
                    Toggle("Show Unlocked Only", isOn: $showUnlockedOnly)
                        .padding(.horizontal, Spacing.screenPadding)
                        .tint(.cageGold)

                    // Achievement grid
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: Spacing.md
                    ) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCard(achievement: achievement)
                                .matchedGeometryEffect(id: achievement.id, in: animation)
                        }
                    }
                    .padding(.horizontal, Spacing.screenPadding)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedCategory)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showUnlockedOnly)
                }
                .padding(.bottom, Spacing.xl)
            }
            .navigationTitle("Achievements")
            .background(Color.primaryBackground)
            .task {
                viewModel.configure(modelContext: modelContext)
                await viewModel.loadAchievements()
            }
            .refreshable {
                await viewModel.loadAchievements()
            }
        }
    }

    private var filteredAchievements: [Achievement] {
        var achievements = viewModel.achievements.filter { $0.category == selectedCategory }
        if showUnlockedOnly {
            achievements = achievements.filter { $0.isUnlocked }
        }
        return achievements
    }
}

// MARK: - Overall Progress Header

/// Displays overall achievement progress and points
struct OverallProgressHeader: View {
    let unlockedCount: Int
    let totalCount: Int
    let points: Int

    private var progressPercentage: Double {
        guard totalCount > 0 else { return 0 }
        return Double(unlockedCount) / Double(totalCount)
    }

    var body: some View {
        VStack(spacing: Spacing.lg) {
            // Trophy icon with glow
            ZStack {
                Circle()
                    .fill(Color.cageGold.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "trophy.fill")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.cageGold)
            }

            // Points display
            VStack(spacing: Spacing.xxxs) {
                Text("\(points)")
                    .font(Typography.heroTitle)
                    .foregroundStyle(Color.cageGold)

                Text("Total Points")
                    .font(Typography.caption1)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            VStack(spacing: Spacing.xs) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.secondaryBackground)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [.cageGold, .orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * progressPercentage)
                    }
                }
                .frame(height: 12)
                .padding(.horizontal, Spacing.xl)

                Text("\(unlockedCount) of \(totalCount) Achievements Unlocked")
                    .font(Typography.caption1)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.lg)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal, Spacing.screenPadding)
    }
}

// MARK: - Category Filter Bar

/// Horizontal scrolling category filter
struct CategoryFilterBar: View {
    let categories: [AchievementCategory]
    @Binding var selected: AchievementCategory

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(categories) { category in
                    CategoryChip(
                        category: category,
                        isSelected: selected == category
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selected = category
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }
}

/// Individual category chip
struct CategoryChip: View {
    let category: AchievementCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.xs) {
                Image(systemName: category.icon)
                    .font(.caption)

                Text(category.rawValue)
                    .font(Typography.caption1Bold)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(
                Capsule()
                    .fill(isSelected ? Color.cageGold : Color.secondaryBackground)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Achievement Card

/// Card displaying a single achievement
struct AchievementCard: View {
    let achievement: Achievement

    @State private var showDetail = false
    @State private var animateUnlock = false

    var body: some View {
        Button(action: { showDetail = true }) {
            VStack(spacing: Spacing.sm) {
                // Icon with lock state
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? Color.cageGold.opacity(0.2) : Color.secondaryBackground)
                        .frame(width: 60, height: 60)

                    if achievement.isUnlocked {
                        Image(systemName: achievement.icon)
                            .font(.title2)
                            .foregroundStyle(Color.cageGold)
                            .scaleEffect(animateUnlock ? 1.2 : 1.0)
                    } else {
                        Image(systemName: "lock.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                }

                // Title
                Text(achievement.title)
                    .font(Typography.caption1Bold)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)
                    .lineLimit(2)

                // Progress or completion
                if achievement.isUnlocked {
                    Text("\(achievement.points) pts")
                        .font(Typography.caption2)
                        .foregroundStyle(Color.cageGold)
                } else if let progress = achievement.progress {
                    ProgressView(value: progress.current, total: progress.target)
                        .tint(Color.cageGold)
                        .padding(.horizontal, Spacing.sm)

                    Text("\(Int(progress.current))/\(Int(progress.target))")
                        .font(Typography.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(Spacing.md)
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .opacity(achievement.isUnlocked ? 1.0 : 0.7)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            AchievementDetailSheet(achievement: achievement)
        }
        .onAppear {
            if achievement.isUnlocked && achievement.unlockedDate != nil {
                // Check if recently unlocked (within last minute for demo)
                if let date = achievement.unlockedDate,
                   Date().timeIntervalSince(date) < 60 {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.5).repeatCount(3)) {
                        animateUnlock = true
                    }
                }
            }
        }
    }
}

// MARK: - Achievement Detail Sheet

/// Detailed view of an achievement
struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Large icon
                    ZStack {
                        Circle()
                            .fill(
                                achievement.isUnlocked
                                    ? LinearGradient(
                                        colors: [.cageGold, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [.gray.opacity(0.3), .gray.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                            )
                            .frame(width: 120, height: 120)
                            .shadow(color: achievement.isUnlocked ? .cageGold.opacity(0.5) : .clear, radius: 20)

                        Image(systemName: achievement.isUnlocked ? achievement.icon : "lock.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, Spacing.xl)

                    // Title and description
                    VStack(spacing: Spacing.sm) {
                        Text(achievement.title)
                            .font(Typography.title1)
                            .multilineTextAlignment(.center)

                        Text(achievement.description)
                            .font(Typography.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }

                    // Points
                    if achievement.isUnlocked {
                        HStack(spacing: Spacing.xs) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color.cageGold)
                            Text("\(achievement.points) Points Earned")
                                .font(Typography.bodyBold)
                        }
                    }

                    // Progress section
                    if !achievement.isUnlocked, let progress = achievement.progress {
                        VStack(spacing: Spacing.md) {
                            Text("Progress")
                                .font(Typography.sectionHeader)

                            ProgressView(value: progress.current, total: progress.target)
                                .tint(Color.cageGold)
                                .scaleEffect(y: 2)

                            Text("\(Int(progress.current)) / \(Int(progress.target))")
                                .font(Typography.title2)
                                .foregroundStyle(Color.cageGold)

                            Text(progress.remainingText)
                                .font(Typography.caption1)
                                .foregroundStyle(.secondary)
                        }
                        .padding(Spacing.lg)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, Spacing.screenPadding)
                    }

                    // Unlock date
                    if let date = achievement.unlockedDate {
                        VStack(spacing: Spacing.xs) {
                            Text("Unlocked")
                                .font(Typography.caption1)
                                .foregroundStyle(.secondary)

                            Text(date, style: .date)
                                .font(Typography.bodyBold)
                        }
                    }

                    // Rarity
                    VStack(spacing: Spacing.xs) {
                        Text("Rarity")
                            .font(Typography.caption1)
                            .foregroundStyle(.secondary)

                        HStack(spacing: Spacing.xs) {
                            ForEach(0..<achievement.rarity.stars, id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .foregroundStyle(Color.cageGold)
                            }
                            ForEach(0..<(5 - achievement.rarity.stars), id: \.self) { _ in
                                Image(systemName: "star")
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Text(achievement.rarity.rawValue)
                            .font(Typography.caption1)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: Spacing.xl)
                }
            }
            .navigationTitle("Achievement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }

                if achievement.isUnlocked {
                    ToolbarItem(placement: .primaryAction) {
                        ShareLink(item: shareText) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
    }

    private var shareText: String {
        """
        I unlocked "\(achievement.title)" in NCDB!
        \(achievement.description)
        +\(achievement.points) points

        #NicolasCage #NCDB
        """
    }
}

// MARK: - Achievement Unlock Celebration

/// Full-screen celebration animation when achievement is unlocked
struct AchievementUnlockCelebration: View {
    let achievement: Achievement
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var confettiOpacity: Double = 1
    @State private var showDetails = false

    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Confetti layer
            ConfettiView()
                .opacity(confettiOpacity)

            // Achievement content
            VStack(spacing: Spacing.xl) {
                Text("Achievement Unlocked!")
                    .font(Typography.title1)
                    .foregroundStyle(Color.cageGold)

                // Icon with glow
                ZStack {
                    // Glow rings
                    ForEach(0..<3) { i in
                        Circle()
                            .stroke(Color.cageGold.opacity(0.3 - Double(i) * 0.1), lineWidth: 2)
                            .frame(width: 140 + CGFloat(i * 20), height: 140 + CGFloat(i * 20))
                            .scaleEffect(scale)
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.cageGold, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: achievement.icon)
                        .font(.system(size: 50))
                        .foregroundStyle(.white)
                }
                .scaleEffect(scale)

                VStack(spacing: Spacing.sm) {
                    Text(achievement.title)
                        .font(Typography.title2)
                        .multilineTextAlignment(.center)

                    Text("+\(achievement.points) Points")
                        .font(Typography.bodyBold)
                        .foregroundStyle(Color.cageGold)
                }
                .opacity(showDetails ? 1 : 0)

                Button("Awesome!") {
                    withAnimation(.spring()) {
                        onDismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.cageGold)
                .opacity(showDetails ? 1 : 0)
            }
            .opacity(opacity)
        }
        .onAppear {
            // Animate in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }

            // Show details after icon animation
            withAnimation(.easeOut.delay(0.5)) {
                showDetails = true
            }

            // Fade confetti
            withAnimation(.easeOut.delay(2)) {
                confettiOpacity = 0
            }
        }
    }
}

// MARK: - Confetti View

/// Animated confetti particles
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(particle.color)
                        .frame(width: particle.size, height: particle.size)
                        .position(particle.position)
                        .rotationEffect(.degrees(particle.rotation))
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                animateParticles(in: geometry.size)
            }
        }
    }

    private func createParticles(in size: CGSize) {
        let colors: [Color] = [.cageGold, .orange, .yellow, .white, .red]

        particles = (0..<50).map { _ in
            ConfettiParticle(
                color: colors.randomElement()!,
                size: CGFloat.random(in: 5...12),
                position: CGPoint(x: size.width / 2, y: -20),
                rotation: Double.random(in: 0...360)
            )
        }
    }

    private func animateParticles(in size: CGSize) {
        for i in particles.indices {
            let delay = Double.random(in: 0...0.5)
            let endX = CGFloat.random(in: 0...size.width)
            let endY = size.height + 50

            withAnimation(.easeOut(duration: 2).delay(delay)) {
                particles[i].position = CGPoint(x: endX, y: endY)
                particles[i].rotation = Double.random(in: 0...720)
            }
        }
    }
}

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    var position: CGPoint
    var rotation: Double
}

// MARK: - Achievement Progress Row

/// Compact row showing achievement progress (for use in other views)
struct AchievementProgressRow: View {
    let achievement: Achievement

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.cageGold.opacity(0.2) : Color.secondaryBackground)
                    .frame(width: 44, height: 44)

                Image(systemName: achievement.isUnlocked ? achievement.icon : "lock.fill")
                    .font(.body)
                    .foregroundStyle(achievement.isUnlocked ? Color.cageGold : .secondary)
            }

            // Title and progress
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(achievement.title)
                    .font(Typography.body)
                    .foregroundStyle(achievement.isUnlocked ? .primary : .secondary)

                if achievement.isUnlocked {
                    Text("Completed")
                        .font(Typography.caption1)
                        .foregroundStyle(Color.cageGold)
                } else if let progress = achievement.progress {
                    ProgressView(value: progress.current, total: progress.target)
                        .tint(Color.cageGold)
                }
            }

            Spacer()

            // Points
            Text("\(achievement.points)")
                .font(Typography.caption1Bold)
                .foregroundStyle(achievement.isUnlocked ? Color.cageGold : .secondary)
        }
        .padding(Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Milestones View

/// View showing major milestones and their progress
struct MilestonesView: View {
    let milestones: [Milestone]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Milestones")
                .font(Typography.sectionHeader)
                .padding(.horizontal, Spacing.screenPadding)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.md) {
                    ForEach(milestones) { milestone in
                        MilestoneCard(milestone: milestone)
                    }
                }
                .padding(.horizontal, Spacing.screenPadding)
            }
        }
    }
}

/// Card displaying a milestone
struct MilestoneCard: View {
    let milestone: Milestone

    var body: some View {
        VStack(spacing: Spacing.md) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(Color.secondaryBackground, lineWidth: 8)

                Circle()
                    .trim(from: 0, to: milestone.progress)
                    .stroke(
                        LinearGradient(
                            colors: [.cageGold, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(milestone.progress * 100))%")
                        .font(Typography.title3)
                        .foregroundStyle(Color.cageGold)
                }
            }
            .frame(width: 80, height: 80)

            Text(milestone.title)
                .font(Typography.caption1Bold)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            Text("\(milestone.current)/\(milestone.target)")
                .font(Typography.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(width: 120)
        .padding(Spacing.md)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Supporting Models

/// Achievement category
enum AchievementCategory: String, CaseIterable, Identifiable {
    case watching = "Watching"
    case rating = "Rating"
    case collecting = "Collecting"
    case exploring = "Exploring"
    case social = "Social"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .watching: return "eye.fill"
        case .rating: return "star.fill"
        case .collecting: return "folder.fill"
        case .exploring: return "globe"
        case .social: return "person.2.fill"
        }
    }
}

/// Achievement rarity
enum AchievementRarity: String {
    case common = "Common"
    case uncommon = "Uncommon"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"

    var stars: Int {
        switch self {
        case .common: return 1
        case .uncommon: return 2
        case .rare: return 3
        case .epic: return 4
        case .legendary: return 5
        }
    }
}

/// Achievement model
struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let points: Int
    let category: AchievementCategory
    let rarity: AchievementRarity
    var isUnlocked: Bool
    var unlockedDate: Date?
    var progress: AchievementProgress?
}

/// Achievement progress tracking
struct AchievementProgress {
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

/// Milestone model
struct Milestone: Identifiable {
    let id: String
    let title: String
    let current: Int
    let target: Int

    var progress: Double {
        min(Double(current) / Double(target), 1.0)
    }
}

// MARK: - Achievements ViewModel

/// ViewModel for managing achievements
@Observable
@MainActor
final class AchievementsViewModel {
    var achievements: [Achievement] = []
    var isLoading = false
    var errorMessage: String?

    private var modelContext: ModelContext?

    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var totalCount: Int {
        achievements.count
    }

    var totalPoints: Int {
        achievements.filter { $0.isUnlocked }.reduce(0) { $0 + $1.points }
    }

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadAchievements() async {
        guard let modelContext else { return }

        isLoading = true

        // Fetch production stats to calculate achievement progress
        let descriptor = FetchDescriptor<Production>()
        do {
            let productions = try modelContext.fetch(descriptor)
            let watchedCount = productions.filter { $0.watched }.count
            let ratedCount = productions.filter { $0.userRating != nil }.count
            let favoritesCount = productions.filter { $0.isFavorite }.count

            // Build achievements with current progress
            achievements = buildAchievements(
                watchedCount: watchedCount,
                ratedCount: ratedCount,
                favoritesCount: favoritesCount,
                totalCount: productions.count
            )
        } catch {
            errorMessage = "Failed to load achievements"
        }

        isLoading = false
    }

    private func buildAchievements(
        watchedCount: Int,
        ratedCount: Int,
        favoritesCount: Int,
        totalCount: Int
    ) -> [Achievement] {
        [
            // Watching achievements
            Achievement(
                id: "first_watch",
                title: "First Steps",
                description: "Watch your first Nicolas Cage movie",
                icon: "play.fill",
                points: 10,
                category: .watching,
                rarity: .common,
                isUnlocked: watchedCount >= 1,
                progress: watchedCount < 1 ? AchievementProgress(current: Double(watchedCount), target: 1) : nil
            ),
            Achievement(
                id: "cage_enthusiast",
                title: "Cage Enthusiast",
                description: "Watch 10 Nicolas Cage movies",
                icon: "film.fill",
                points: 50,
                category: .watching,
                rarity: .uncommon,
                isUnlocked: watchedCount >= 10,
                progress: watchedCount < 10 ? AchievementProgress(current: Double(watchedCount), target: 10) : nil
            ),
            Achievement(
                id: "cage_devotee",
                title: "Cage Devotee",
                description: "Watch 25 Nicolas Cage movies",
                icon: "star.circle.fill",
                points: 100,
                category: .watching,
                rarity: .rare,
                isUnlocked: watchedCount >= 25,
                progress: watchedCount < 25 ? AchievementProgress(current: Double(watchedCount), target: 25) : nil
            ),
            Achievement(
                id: "cage_master",
                title: "Cage Master",
                description: "Watch 50 Nicolas Cage movies",
                icon: "crown.fill",
                points: 250,
                category: .watching,
                rarity: .epic,
                isUnlocked: watchedCount >= 50,
                progress: watchedCount < 50 ? AchievementProgress(current: Double(watchedCount), target: 50) : nil
            ),
            Achievement(
                id: "one_true_god",
                title: "One True God",
                description: "Watch every Nicolas Cage movie",
                icon: "sparkles",
                points: 1000,
                category: .watching,
                rarity: .legendary,
                isUnlocked: watchedCount >= totalCount && totalCount > 0,
                progress: AchievementProgress(current: Double(watchedCount), target: Double(totalCount))
            ),

            // Rating achievements
            Achievement(
                id: "first_rating",
                title: "Film Critic",
                description: "Rate your first movie",
                icon: "star.fill",
                points: 10,
                category: .rating,
                rarity: .common,
                isUnlocked: ratedCount >= 1,
                progress: ratedCount < 1 ? AchievementProgress(current: Double(ratedCount), target: 1) : nil
            ),
            Achievement(
                id: "rating_enthusiast",
                title: "Opinionated",
                description: "Rate 10 movies",
                icon: "star.leadinghalf.filled",
                points: 50,
                category: .rating,
                rarity: .uncommon,
                isUnlocked: ratedCount >= 10,
                progress: ratedCount < 10 ? AchievementProgress(current: Double(ratedCount), target: 10) : nil
            ),
            Achievement(
                id: "rating_master",
                title: "Professional Critic",
                description: "Rate 25 movies",
                icon: "checkmark.seal.fill",
                points: 100,
                category: .rating,
                rarity: .rare,
                isUnlocked: ratedCount >= 25,
                progress: ratedCount < 25 ? AchievementProgress(current: Double(ratedCount), target: 25) : nil
            ),

            // Collecting achievements
            Achievement(
                id: "first_favorite",
                title: "Heart of Gold",
                description: "Add your first favorite",
                icon: "heart.fill",
                points: 10,
                category: .collecting,
                rarity: .common,
                isUnlocked: favoritesCount >= 1,
                progress: favoritesCount < 1 ? AchievementProgress(current: Double(favoritesCount), target: 1) : nil
            ),
            Achievement(
                id: "collector",
                title: "Collector",
                description: "Add 5 favorites",
                icon: "heart.circle.fill",
                points: 50,
                category: .collecting,
                rarity: .uncommon,
                isUnlocked: favoritesCount >= 5,
                progress: favoritesCount < 5 ? AchievementProgress(current: Double(favoritesCount), target: 5) : nil
            ),
        ]
    }
}

// MARK: - Previews

#Preview("Achievements View") {
    AchievementsView()
        .modelContainer(for: Production.self, inMemory: true)
}

#Preview("Achievement Card - Unlocked") {
    AchievementCard(
        achievement: Achievement(
            id: "test",
            title: "First Steps",
            description: "Watch your first movie",
            icon: "play.fill",
            points: 10,
            category: .watching,
            rarity: .common,
            isUnlocked: true,
            unlockedDate: Date()
        )
    )
    .frame(width: 160)
    .padding()
}

#Preview("Achievement Card - Locked") {
    AchievementCard(
        achievement: Achievement(
            id: "test",
            title: "Cage Master",
            description: "Watch 50 movies",
            icon: "crown.fill",
            points: 250,
            category: .watching,
            rarity: .epic,
            isUnlocked: false,
            progress: AchievementProgress(current: 23, target: 50)
        )
    )
    .frame(width: 160)
    .padding()
}

#Preview("Unlock Celebration") {
    AchievementUnlockCelebration(
        achievement: Achievement(
            id: "test",
            title: "Cage Enthusiast",
            description: "Watch 10 Nicolas Cage movies",
            icon: "film.fill",
            points: 50,
            category: .watching,
            rarity: .uncommon,
            isUnlocked: true
        )
    ) {
        print("Dismissed")
    }
}
