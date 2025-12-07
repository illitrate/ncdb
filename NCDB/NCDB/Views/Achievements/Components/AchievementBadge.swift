//
//  AchievementBadge.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Visual badge component for displaying achievement status
struct AchievementBadge: View {
    let definition: AchievementDefinition
    let isUnlocked: Bool
    let progress: Double // 0.0 to 1.0

    var body: some View {
        VStack(spacing: Spacing.sm) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(categoryGradient)
                    .frame(width: 80, height: 80)
                    .opacity(isUnlocked ? 1.0 : 0.3)

                // Progress ring for locked achievements
                if !isUnlocked && progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            Color.cageGold,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 84, height: 84)
                        .rotationEffect(.degrees(-90))
                }

                // Icon
                Image(systemName: definition.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isUnlocked ? .white : Color.tertiaryText)
            }

            // Title
            Text(definition.title)
                .font(.caption.bold())
                .foregroundStyle(isUnlocked ? Color.primaryText : Color.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32)

            // Progress text for locked achievements
            if !isUnlocked && progress > 0 {
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .foregroundStyle(Color.tertiaryText)
            } else if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(Color.cageGold)
            } else {
                Text("Locked")
                    .font(.caption2)
                    .foregroundStyle(Color.tertiaryText)
            }
        }
        .frame(width: 100)
    }

    private var categoryGradient: LinearGradient {
        let color = categoryColor
        return LinearGradient(
            colors: [color, color.opacity(0.7)],
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
}

/// Compact badge variant for lists
struct CompactAchievementBadge: View {
    let definition: AchievementDefinition
    let isUnlocked: Bool
    let unlockedAt: Date?

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(categoryGradient)
                    .frame(width: 50, height: 50)
                    .opacity(isUnlocked ? 1.0 : 0.3)

                Image(systemName: definition.icon)
                    .font(.title3)
                    .foregroundStyle(isUnlocked ? .white : Color.tertiaryText)
            }

            // Info
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(definition.title)
                        .font(.headline)
                        .foregroundStyle(isUnlocked ? Color.primaryText : Color.secondaryText)

                    if isUnlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundStyle(Color.cageGold)
                    }
                }

                Text(definition.description)
                    .font(.caption)
                    .foregroundStyle(Color.tertiaryText)
                    .lineLimit(2)

                if let date = unlockedAt, isUnlocked {
                    Text("Unlocked \(date.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption2)
                        .foregroundStyle(Color.cageGold)
                }
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(Color.glassLight)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var categoryGradient: LinearGradient {
        let color = categoryColor
        return LinearGradient(
            colors: [color, color.opacity(0.7)],
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
}
