// NCDB Spacing System
// Consistent spacing, padding, and layout values across the app

import SwiftUI

// MARK: - Spacing Scale

/// 8-point grid spacing system for consistent layouts
/// All spacing values are multiples of 4, with primary increments of 8
enum Spacing {

    // MARK: - Base Unit
    static let unit: CGFloat = 4

    // MARK: - Spacing Scale

    /// 2pt - Minimal spacing (icon-to-text, tight elements)
    static let xxxs: CGFloat = 2

    /// 4pt - Extra extra small (between related inline elements)
    static let xxs: CGFloat = 4

    /// 8pt - Extra small (between closely related elements)
    static let xs: CGFloat = 8

    /// 12pt - Small (default inline spacing)
    static let sm: CGFloat = 12

    /// 16pt - Medium (standard content spacing)
    static let md: CGFloat = 16

    /// 20pt - Medium large (between sections in cards)
    static let lg: CGFloat = 20

    /// 24pt - Large (between content groups)
    static let xl: CGFloat = 24

    /// 32pt - Extra large (section dividers)
    static let xxl: CGFloat = 32

    /// 40pt - Extra extra large (major section breaks)
    static let xxxl: CGFloat = 40

    /// 48pt - Huge (screen-level spacing)
    static let huge: CGFloat = 48

    /// 64pt - Maximum (hero sections)
    static let max: CGFloat = 64

    // MARK: - Semantic Spacing

    /// Content padding from screen edges
    static let screenPadding: CGFloat = 16

    /// Safe area additional padding
    static let safeAreaPadding: CGFloat = 8

    /// Card internal padding
    static let cardPadding: CGFloat = 16

    /// Card internal padding (compact)
    static let cardPaddingCompact: CGFloat = 12

    /// Space between cards in a list
    static let cardSpacing: CGFloat = 12

    /// Space between sections on a screen
    static let sectionSpacing: CGFloat = 24

    /// Space between items in a horizontal scroll
    static let horizontalScrollSpacing: CGFloat = 12

    /// Space between items in a grid
    static let gridSpacing: CGFloat = 16

    /// Space between label and value
    static let labelValueSpacing: CGFloat = 4

    /// Space between icon and text
    static let iconTextSpacing: CGFloat = 8

    /// Space between stacked buttons
    static let buttonSpacing: CGFloat = 12

    /// Space between form fields
    static let formFieldSpacing: CGFloat = 16

    /// Navigation bar bottom spacing
    static let navBarSpacing: CGFloat = 8

    /// Tab bar top spacing
    static let tabBarSpacing: CGFloat = 8
}

// MARK: - Insets

/// Pre-defined EdgeInsets for common use cases
enum Insets {

    /// Standard screen content insets
    static let screen = EdgeInsets(
        top: Spacing.md,
        leading: Spacing.screenPadding,
        bottom: Spacing.md,
        trailing: Spacing.screenPadding
    )

    /// Card internal insets
    static let card = EdgeInsets(
        top: Spacing.cardPadding,
        leading: Spacing.cardPadding,
        bottom: Spacing.cardPadding,
        trailing: Spacing.cardPadding
    )

    /// Compact card insets
    static let cardCompact = EdgeInsets(
        top: Spacing.cardPaddingCompact,
        leading: Spacing.cardPaddingCompact,
        bottom: Spacing.cardPaddingCompact,
        trailing: Spacing.cardPaddingCompact
    )

    /// List row insets
    static let listRow = EdgeInsets(
        top: Spacing.sm,
        leading: Spacing.screenPadding,
        bottom: Spacing.sm,
        trailing: Spacing.screenPadding
    )

    /// Button content insets
    static let button = EdgeInsets(
        top: Spacing.sm,
        leading: Spacing.lg,
        bottom: Spacing.sm,
        trailing: Spacing.lg
    )

    /// Small button insets
    static let buttonSmall = EdgeInsets(
        top: Spacing.xs,
        leading: Spacing.md,
        bottom: Spacing.xs,
        trailing: Spacing.md
    )

    /// Badge insets
    static let badge = EdgeInsets(
        top: Spacing.xxs,
        leading: Spacing.xs,
        bottom: Spacing.xxs,
        trailing: Spacing.xs
    )

    /// Section header insets
    static let sectionHeader = EdgeInsets(
        top: Spacing.lg,
        leading: Spacing.screenPadding,
        bottom: Spacing.xs,
        trailing: Spacing.screenPadding
    )

    /// Modal sheet insets
    static let sheet = EdgeInsets(
        top: Spacing.xl,
        leading: Spacing.screenPadding,
        bottom: Spacing.xxl,
        trailing: Spacing.screenPadding
    )

    /// Zero insets
    static let zero = EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
}

// MARK: - Size Constants

/// Common size values for UI elements
enum Sizes {

    // MARK: - Touch Targets
    /// Minimum touch target (Apple HIG: 44pt)
    static let minTouchTarget: CGFloat = 44

    /// Standard button height
    static let buttonHeight: CGFloat = 50

    /// Small button height
    static let buttonHeightSmall: CGFloat = 36

    /// Large button height
    static let buttonHeightLarge: CGFloat = 56

    // MARK: - Icons
    /// Small icon size
    static let iconSmall: CGFloat = 16

    /// Medium icon size
    static let iconMedium: CGFloat = 24

    /// Large icon size
    static let iconLarge: CGFloat = 32

    /// Extra large icon size
    static let iconXLarge: CGFloat = 48

    // MARK: - Avatars / Thumbnails
    /// Small thumbnail
    static let thumbnailSmall: CGFloat = 40

    /// Medium thumbnail
    static let thumbnailMedium: CGFloat = 60

    /// Large thumbnail
    static let thumbnailLarge: CGFloat = 80

    /// Profile avatar size
    static let avatar: CGFloat = 100

    // MARK: - Cards
    /// Minimum card width
    static let cardMinWidth: CGFloat = 140

    /// Maximum card width
    static let cardMaxWidth: CGFloat = 400

    /// Standard card height
    static let cardHeight: CGFloat = 200

    /// Compact card height
    static let cardHeightCompact: CGFloat = 120

    // MARK: - Corner Radius
    /// Small corner radius (badges, tags)
    static let cornerRadiusSmall: CGFloat = 6

    /// Medium corner radius (buttons, inputs)
    static let cornerRadiusMedium: CGFloat = 10

    /// Large corner radius (cards)
    static let cornerRadiusLarge: CGFloat = 16

    /// Extra large corner radius (sheets, modals)
    static let cornerRadiusXLarge: CGFloat = 24

    /// Full corner radius (pills, capsules)
    static let cornerRadiusFull: CGFloat = 9999

    // MARK: - Borders
    /// Thin border width
    static let borderThin: CGFloat = 0.5

    /// Standard border width
    static let borderStandard: CGFloat = 1

    /// Thick border width
    static let borderThick: CGFloat = 2

    // MARK: - Shadows
    /// Small shadow radius
    static let shadowSmall: CGFloat = 4

    /// Medium shadow radius
    static let shadowMedium: CGFloat = 8

    /// Large shadow radius
    static let shadowLarge: CGFloat = 16

    /// Extra large shadow radius
    static let shadowXLarge: CGFloat = 24
}

// MARK: - View Extensions

extension View {

    /// Apply standard screen padding
    func screenPadding() -> some View {
        self.padding(.horizontal, Spacing.screenPadding)
    }

    /// Apply card padding
    func cardPadding() -> some View {
        self.padding(Spacing.cardPadding)
    }

    /// Apply section spacing above
    func sectionSpacing() -> some View {
        self.padding(.top, Spacing.sectionSpacing)
    }

    /// Apply standard horizontal scroll padding
    func horizontalScrollPadding() -> some View {
        self
            .padding(.horizontal, Spacing.screenPadding)
            .padding(.vertical, Spacing.xs)
    }

    /// Apply minimum touch target size
    func minTouchTarget() -> some View {
        self.frame(minWidth: Sizes.minTouchTarget, minHeight: Sizes.minTouchTarget)
    }

    /// Apply card corner radius
    func cardCornerRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusLarge))
    }

    /// Apply small corner radius
    func smallCornerRadius() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusSmall))
    }

    /// Apply standard shadow
    func standardShadow() -> some View {
        self.shadow(color: .black.opacity(0.15), radius: Sizes.shadowMedium, x: 0, y: 4)
    }

    /// Apply card shadow (more prominent)
    func cardShadow() -> some View {
        self.shadow(color: .black.opacity(0.25), radius: Sizes.shadowLarge, x: 0, y: 8)
    }

    /// Apply glass shadow (subtle glow)
    func glassShadow() -> some View {
        self.shadow(color: .black.opacity(0.3), radius: Sizes.shadowMedium, x: 0, y: 4)
    }
}

// MARK: - Layout Helpers

extension View {

    /// Stack with standard vertical spacing
    func vStackSpacing(_ spacing: CGFloat = Spacing.md) -> some View {
        // Note: This is for documentation; actual usage would be VStack(spacing: spacing)
        self
    }

    /// Stack with standard horizontal spacing
    func hStackSpacing(_ spacing: CGFloat = Spacing.sm) -> some View {
        // Note: This is for documentation; actual usage would be HStack(spacing: spacing)
        self
    }
}

// MARK: - Grid Layouts

/// Standard grid configurations
enum GridLayouts {

    /// 2-column grid for movie posters
    static let posterGrid = [
        GridItem(.flexible(), spacing: Spacing.gridSpacing),
        GridItem(.flexible(), spacing: Spacing.gridSpacing)
    ]

    /// 3-column grid for thumbnails
    static let thumbnailGrid = [
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm),
        GridItem(.flexible(), spacing: Spacing.sm)
    ]

    /// Adaptive grid (minimum 140pt width)
    static let adaptiveGrid = [
        GridItem(.adaptive(minimum: 140), spacing: Spacing.gridSpacing)
    ]

    /// Single column list
    static let singleColumn = [
        GridItem(.flexible())
    ]
}

// MARK: - Preview

#Preview("Spacing Showcase") {
    ScrollView {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            Text("Spacing Scale")
                .font(.headline)

            VStack(alignment: .leading, spacing: Spacing.xs) {
                SpacingRow(name: "xxxs", value: Spacing.xxxs)
                SpacingRow(name: "xxs", value: Spacing.xxs)
                SpacingRow(name: "xs", value: Spacing.xs)
                SpacingRow(name: "sm", value: Spacing.sm)
                SpacingRow(name: "md", value: Spacing.md)
                SpacingRow(name: "lg", value: Spacing.lg)
                SpacingRow(name: "xl", value: Spacing.xl)
                SpacingRow(name: "xxl", value: Spacing.xxl)
            }

            Divider()

            Text("Corner Radius")
                .font(.headline)

            HStack(spacing: Spacing.md) {
                RoundedRectangle(cornerRadius: Sizes.cornerRadiusSmall)
                    .fill(Color.cageGold)
                    .frame(width: 60, height: 40)
                    .overlay(Text("S").font(.caption))

                RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium)
                    .fill(Color.cageGold)
                    .frame(width: 60, height: 40)
                    .overlay(Text("M").font(.caption))

                RoundedRectangle(cornerRadius: Sizes.cornerRadiusLarge)
                    .fill(Color.cageGold)
                    .frame(width: 60, height: 40)
                    .overlay(Text("L").font(.caption))

                Capsule()
                    .fill(Color.cageGold)
                    .frame(width: 60, height: 40)
                    .overlay(Text("Full").font(.caption))
            }
        }
        .padding(Spacing.screenPadding)
    }
    .background(Color.primaryBackground)
}

struct SpacingRow: View {
    let name: String
    let value: CGFloat

    var body: some View {
        HStack {
            Text(name)
                .font(.system(.body, design: .monospaced))
                .frame(width: 50, alignment: .leading)

            Rectangle()
                .fill(Color.cageGold)
                .frame(width: value, height: 20)

            Text("\(Int(value))pt")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
