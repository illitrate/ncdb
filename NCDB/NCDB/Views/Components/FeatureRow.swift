//
//  FeatureRow.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-08.
//

import SwiftUI

/// Reusable feature row component for displaying icon + title + description
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.cageGold)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        FeatureRow(
            icon: "checkmark.circle.fill",
            title: "Track",
            description: "Mark movies as watched and rate them"
        )
        FeatureRow(
            icon: "film.fill",
            title: "Browse",
            description: "Explore Nicolas Cage's complete filmography"
        )
        FeatureRow(
            icon: "trophy.fill",
            title: "Rank",
            description: "Create your personal ranking"
        )
    }
    .padding()
    .background(Color.primaryBackground)
}
