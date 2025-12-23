//
//  AchievementsView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SwiftData

/// Main achievements view with grid display
struct AchievementsView: View {
    @Query private var unlockedAchievements: [Achievement]
    @Query private var productions: [Production]
    @Query private var watchEvents: [WatchEvent]

    @State private var selectedCategory: AchievementGroup?
    @State private var selectedAchievement: AchievementDefinition?
    @State private var showAbout = false

    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 120), spacing: Spacing.md)
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                // Progress card
                progressCard

                // Category filter
                categoryPicker

                // Achievements grid
                LazyVGrid(columns: columns, spacing: Spacing.md) {
                    ForEach(filteredAchievements) { definition in
                        Button {
                            selectedAchievement = definition
                            HapticManager.shared.light()
                        } label: {
                            AchievementBadge(
                                definition: definition,
                                isUnlocked: isUnlocked(definition),
                                progress: getProgress(for: definition)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Spacing.md)
            }
            .padding(.vertical, Spacing.md)
        }
        .background(Color.primaryBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                NCDBLogoView {
                    showAbout = true
                }
            }
        }
        .sheet(item: $selectedAchievement) { definition in
            AchievementDetailView(
                definition: definition,
                isUnlocked: isUnlocked(definition),
                unlockedAt: getUnlockedDate(definition),
                progress: getProgress(for: definition)
            )
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }

    // MARK: - Subviews

    private var progressCard: some View {
        VStack(spacing: Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Overall Progress")
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)

                    Text("\(unlockedCount) of \(totalCount) unlocked")
                        .font(.caption)
                        .foregroundStyle(Color.secondaryText)
                }

                Spacer()

                // Percentage circle
                ZStack {
                    Circle()
                        .stroke(Color.glassLight, lineWidth: 6)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: completionPercentage / 100.0)
                        .stroke(Color.cageGold, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(completionPercentage))%")
                        .font(.caption.bold())
                        .foregroundStyle(Color.primaryText)
                }
            }
        }
        .padding(Spacing.md)
        .background(Color.glassLight)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, Spacing.md)
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                // All category
                CategoryChip(
                    title: "All",
                    isSelected: selectedCategory == nil,
                    color: .gray
                ) {
                    selectedCategory = nil
                }

                // Individual categories
                ForEach(AchievementGroup.allCases, id: \.self) { category in
                    CategoryChip(
                        title: category.rawValue,
                        isSelected: selectedCategory == category,
                        color: categoryColor(category)
                    ) {
                        selectedCategory = category
                    }
                }
            }
            .padding(.horizontal, Spacing.md)
        }
    }

    // MARK: - Helper Properties

    private var filteredAchievements: [AchievementDefinition] {
        let allAchievements = AchievementManager.shared.allAchievements

        if let category = selectedCategory {
            return allAchievements.filter { $0.category == category }
        }

        return allAchievements
    }

    private var unlockedCount: Int {
        unlockedAchievements.count
    }

    private var totalCount: Int {
        AchievementManager.shared.allAchievements.count
    }

    private var completionPercentage: Double {
        guard totalCount > 0 else { return 0.0 }
        return Double(unlockedCount) / Double(totalCount) * 100.0
    }

    // MARK: - Helper Methods

    private func isUnlocked(_ definition: AchievementDefinition) -> Bool {
        unlockedAchievements.contains { $0.achievementID == definition.id }
    }

    private func getUnlockedDate(_ definition: AchievementDefinition) -> Date? {
        unlockedAchievements.first { $0.achievementID == definition.id }?.unlockedAt
    }

    private func getProgress(for definition: AchievementDefinition) -> Double {
        let currentStreak = WatchHistoryManager.shared.getCurrentStreak()
        return AchievementManager.shared.getProgress(
            for: definition,
            productions: productions,
            watchEvents: watchEvents,
            currentStreak: currentStreak
        )
    }

    private func categoryColor(_ category: AchievementGroup) -> Color {
        switch category.color {
        case "blue": return .blue
        case "cageGold": return .cageGold
        case "orange": return .orange
        case "purple": return .purple
        case "green": return .green
        case "pink": return .pink
        default: return .gray
        }
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(isSelected ? .white : Color.secondaryText)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.xs)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color.glassLight)
                )
        }
    }
}
