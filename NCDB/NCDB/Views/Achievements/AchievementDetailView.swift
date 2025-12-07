//
//  AchievementDetailView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Detailed view for a single achievement
struct AchievementDetailView: View {
    let definition: AchievementDefinition
    let isUnlocked: Bool
    let unlockedAt: Date?
    let progress: Double

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Large icon
                    achievementIcon

                    // Title and description
                    VStack(spacing: Spacing.sm) {
                        Text(definition.title)
                            .font(.title2.bold())
                            .foregroundStyle(Color.primaryText)
                            .multilineTextAlignment(.center)

                        Text(definition.description)
                            .font(.body)
                            .foregroundStyle(Color.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, Spacing.lg)
                    }

                    // Category badge
                    Text(definition.category.rawValue)
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, Spacing.md)
                        .padding(.vertical, Spacing.xs)
                        .background(
                            Capsule()
                                .fill(categoryColor)
                        )

                    Divider()
                        .padding(.horizontal, Spacing.lg)

                    // Status section
                    VStack(spacing: Spacing.md) {
                        if isUnlocked {
                            unlockedSection
                        } else {
                            progressSection
                        }

                        // Requirement details
                        requirementSection
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                .padding(.vertical, Spacing.lg)
            }
            .background(Color.primaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Subviews

    private var achievementIcon: some View {
        ZStack {
            Circle()
                .fill(categoryGradient)
                .frame(width: 120, height: 120)
                .opacity(isUnlocked ? 1.0 : 0.3)

            // Progress ring for locked achievements
            if !isUnlocked && progress > 0 {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        Color.cageGold,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 126, height: 126)
                    .rotationEffect(.degrees(-90))
            }

            Image(systemName: definition.icon)
                .font(.system(size: 50))
                .foregroundStyle(isUnlocked ? .white : Color.tertiaryText)

            // Checkmark overlay for unlocked
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title)
                    .foregroundStyle(Color.cageGold)
                    .background(
                        Circle()
                            .fill(Color.primaryBackground)
                            .frame(width: 28, height: 28)
                    )
                    .offset(x: 45, y: -45)
            }
        }
    }

    private var unlockedSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(Color.cageGold)

                Text("Unlocked!")
                    .font(.title3.bold())
                    .foregroundStyle(Color.cageGold)
            }

            if let date = unlockedAt {
                Text("Achieved on \(date.formatted(date: .long, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
            }
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity)
        .background(Color.cageGold.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var progressSection: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                Text("Progress")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.headline.bold())
                    .foregroundStyle(Color.cageGold)
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.glassLight)
                        .frame(height: 8)

                    Rectangle()
                        .fill(Color.cageGold)
                        .frame(width: geometry.size.width * progress, height: 8)
                }
            }
            .frame(height: 8)
            .clipShape(Capsule())
        }
        .padding(Spacing.md)
        .background(Color.glassLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var requirementSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Requirement")
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            Text(requirementDescription)
                .font(.body)
                .foregroundStyle(Color.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(Color.glassLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Helper Properties

    private var categoryGradient: LinearGradient {
        LinearGradient(
            colors: [categoryColor, categoryColor.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var categoryColor: Color {
        switch definition.category.color {
        case "blue": return .blue
        case "cageGold": return .cageGold
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "pink": return .pink
        default: return .gray
        }
    }

    private var requirementDescription: String {
        switch definition.requirement {
        case .watchCount(let count):
            return "Watch \(count) Nicolas Cage \(count == 1 ? "movie" : "movies")"
        case .watchAll:
            return "Watch every available Nicolas Cage movie"
        case .watchInTimeframe(let count, let days):
            return "Watch \(count) movies within \(days) \(days == 1 ? "day" : "days")"
        case .rewatchCount(let count):
            return "Watch the same movie \(count) times"
        case .ratingCount(let count):
            return "Rate \(count) \(count == 1 ? "movie" : "movies")"
        case .giveRating(let rating):
            return "Give a movie a \(rating)-star rating"
        case .averageRatingRange(let min, let max):
            return "Maintain an average rating between \(String(format: "%.1f", min)) and \(String(format: "%.1f", max)) stars"
        case .averageRatingAbove(let threshold):
            return "Maintain an average rating above \(String(format: "%.1f", threshold)) stars"
        case .streak(let days):
            return "Watch movies on \(days) consecutive days"
        case .rankingCount(let count):
            return "Rank \(count) \(count == 1 ? "movie" : "movies")"
        case .shareRankings:
            return "Share your rankings"
        case .genreCount(let genre, let count):
            return "Watch \(count) \(genre) movies"
        case .decadeCount(let decade, let count):
            return "Watch \(count) movies from the \(decade)s"
        case .watchSpecificMovie:
            return "Watch this specific Nicolas Cage classic"
        case .reviewCount(let count):
            return "Write \(count) \(count == 1 ? "review" : "reviews")"
        case .exportData:
            return "Export your data"
        case .earlyAdopter:
            return "Use NCDB within the first month of launch"
        }
    }
}
