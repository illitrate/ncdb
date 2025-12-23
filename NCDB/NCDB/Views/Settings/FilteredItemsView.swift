//
//  FilteredItemsView.swift
//  NCDB
//
//  Displays all filtered items and allows user overrides
//

import SwiftUI
import SwiftData

/// View showing all items that would be filtered based on current settings
struct FilteredItemsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var allProductions: [Production]
    @Query private var preferences: [UserPreferences]

    @State private var searchText = ""

    private var userPrefs: UserPreferences? {
        preferences.first
    }

    /// All productions that would be filtered (either non-acting or documentaries)
    private var filteredProductions: [Production] {
        allProductions.filter { production in
            production.wouldBeFiltered
        }.sorted { $0.title < $1.title }
    }

    /// Filter based on search text
    private var displayedProductions: [Production] {
        if searchText.isEmpty {
            return filteredProductions
        }
        return filteredProductions.filter { production in
            production.title.localizedCaseInsensitiveContains(searchText) ||
            (production.characterName?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    /// Count of manually included items
    private var manuallyIncludedCount: Int {
        filteredProductions.filter { $0.manuallyIncluded }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Stats header
                statsHeader

                // List of filtered items
                if displayedProductions.isEmpty {
                    emptyState
                } else {
                    filteredItemsList
                }
            }
            .navigationTitle("Filtered Items")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.cageGold)
                }
            }
            .searchable(text: $searchText, prompt: "Search filtered items")
        }
    }

    // MARK: - Subviews

    private var statsHeader: some View {
        VStack(spacing: Spacing.sm) {
            HStack(spacing: Spacing.lg) {
                StatCard(
                    title: "Filtered",
                    value: "\(filteredProductions.count)",
                    icon: "eye.slash.fill"
                )

                StatCard(
                    title: "Included",
                    value: "\(manuallyIncludedCount)",
                    icon: "checkmark.circle.fill"
                )
            }
            .padding(.horizontal, Spacing.md)
            .padding(.top, Spacing.md)

            Text("Tap items to include them in your library despite filters")
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
                .padding(.bottom, Spacing.sm)
        }
        .background(Color.primaryBackground)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(Color.cageGold)

            Text("No Filtered Items")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(Color.primaryText)

            Text("All items from TMDb are included in your library")
                .font(.body)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            Spacer()
        }
    }

    private var filteredItemsList: some View {
        List {
            ForEach(displayedProductions) { production in
                FilteredItemRow(production: production)
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Filtered Item Row

struct FilteredItemRow: View {
    @Bindable var production: Production

    private var filterReason: String {
        var reasons: [String] = []
        if production.productionType == .documentary {
            reasons.append("Documentary")
        }
        if production.isNonActingAppearance {
            reasons.append("Non-acting")
        }
        return reasons.joined(separator: " • ")
    }

    private var characterDisplay: String {
        if let character = production.characterName, !character.isEmpty {
            return "as \(character)"
        }
        return "No character listed"
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Checkbox
            Button {
                HapticManager.shared.buttonTap()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    production.manuallyIncluded.toggle()
                }
            } label: {
                Image(systemName: production.manuallyIncluded ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(production.manuallyIncluded ? Color.cageGold : Color.secondaryText)
            }
            .buttonStyle(.plain)

            // Item details
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(production.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.primaryText)

                Text(characterDisplay)
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)

                HStack(spacing: Spacing.xs) {
                    Text(String(production.releaseYear))
                        .font(.caption2)
                        .foregroundStyle(Color.tertiaryText)

                    Text("•")
                        .foregroundStyle(Color.tertiaryText)

                    Text(filterReason)
                        .font(.caption2)
                        .foregroundStyle(Color.cageGold)
                }
            }

            Spacer()
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }
}

// MARK: - Preview

#Preview {
    FilteredItemsView()
        .modelContainer(for: [Production.self, UserPreferences.self], inMemory: true)
}
