//
//  AboutView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-08.
//

import SwiftUI

/// About view with app information, usage instructions, and TMDb setup guide
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.xl) {
                    // Icon
                    Image("AppIcon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .shadow(color: .cageGold.opacity(0.5), radius: 20)
                        .padding(.top, Spacing.lg)

                    // Branding
                    VStack(spacing: Spacing.sm) {
                        NCDBLogoView(onTap: { dismiss() })
/*                        Text("NCDB")
                            .font(Typography.heroTitle)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cageGold, .cageGold.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .cageGold.opacity(0.3), radius: 10)
 */

                        Text("Nicolas Cage Database")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.cageGold, .cageGold.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                    }

                    // Description
                    Text("Your personal companion for exploring, tracking, and celebrating the complete filmography of Nicolas Cage.")
                        .font(Typography.body)
                        .foregroundStyle(Color.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.xl)

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, Spacing.xl)

                    // How to Use
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("How to Use NCDB")
                            .font(Typography.title2)
                            .foregroundStyle(Color.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.xl)

                        VStack(alignment: .leading, spacing: Spacing.md) {
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
                            FeatureRow(
                                icon: "chart.bar.fill",
                                title: "Stats",
                                description: "View insights and achievements"
                            )
                        }
                        .padding(.horizontal, Spacing.xl)
                    }

                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.horizontal, Spacing.xl)

                    // TMDb Setup
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text("Setting Up TMDb")
                            .font(Typography.title2)
                            .foregroundStyle(Color.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, Spacing.xl)

                        VStack(alignment: .leading, spacing: Spacing.sm) {
                            SetupStepView(
                                number: 1,
                                text: "Visit themoviedb.org and create a free account"
                            )
                            SetupStepView(
                                number: 2,
                                text: "Go to Settings → API and request an API key"
                            )
                            SetupStepView(
                                number: 3,
                                text: "Copy your API key"
                            )
                            SetupStepView(
                                number: 4,
                                text: "Open NCDB Settings → TMDb Configuration and paste your key"
                            )
                        }
                        .padding(.horizontal, Spacing.xl)
                    }

                    // Footer
                    VStack(spacing: Spacing.xs) {
                        Text("Version \(AppConstants.appVersion)")
                            .font(Typography.caption1)
                            .foregroundStyle(Color.tertiaryText)

                        Text("Swipe down to close")
                            .font(Typography.caption2)
                            .foregroundStyle(Color.tertiaryText)
                    }
                    .padding(.top, Spacing.lg)
                    .padding(.bottom, Spacing.xxl)
                }
            }
            .background(Color.primaryBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("About")
                        .font(Typography.navTitle)
                        .foregroundStyle(Color.primaryText)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

/// Step view for TMDb setup instructions
struct SetupStepView: View {
    let number: Int
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.sm) {
            Text("\(number).")
                .font(Typography.bodyBold)
                .foregroundStyle(Color.cageGold)
                .frame(width: 24, alignment: .leading)

            Text(text)
                .font(Typography.bodySecondary)
                .foregroundStyle(Color.secondaryText)
        }
    }
}

#Preview {
    AboutView()
}
