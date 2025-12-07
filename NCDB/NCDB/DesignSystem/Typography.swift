// NCDB Typography System
// Consistent text styles across the app, designed for Liquid Glass aesthetic

import SwiftUI

// MARK: - Typography Constants

enum Typography {

    // MARK: - Font Family

    /// Primary font family - system default for optimal Liquid Glass integration
    /// iOS 26's Liquid Glass works best with system fonts that adapt to the material
    static let primaryFont: Font.Design = .default

    /// Rounded font for friendly, approachable numbers and badges
    static let roundedFont: Font.Design = .rounded

    /// Monospaced font for statistics and data displays
    static let monospacedFont: Font.Design = .monospaced

    // MARK: - Display Styles (Heroes, Headers)

    /// Large display for hero sections (movie titles on detail views)
    static let heroTitle = Font.system(size: 34, weight: .bold, design: .default)

    /// Large number displays (statistics, counts)
    static let heroNumber = Font.system(size: 64, weight: .bold, design: .rounded)

    /// Medium display numbers
    static let displayNumber = Font.system(size: 48, weight: .bold, design: .rounded)

    // MARK: - Title Styles

    /// Primary title (screen titles, section headers)
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)

    /// Secondary title (card headers, group titles)
    static let title2 = Font.system(size: 22, weight: .semibold, design: .default)

    /// Tertiary title (subsection headers)
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)

    // MARK: - Body Styles

    /// Primary body text
    static let body = Font.system(size: 17, weight: .regular, design: .default)

    /// Emphasized body text
    static let bodyBold = Font.system(size: 17, weight: .semibold, design: .default)

    /// Secondary body (descriptions, supporting text)
    static let bodySecondary = Font.system(size: 15, weight: .regular, design: .default)

    // MARK: - Caption Styles

    /// Primary caption (labels, timestamps)
    static let caption1 = Font.system(size: 13, weight: .regular, design: .default)

    /// Bold caption (badges, tags)
    static let caption1Bold = Font.system(size: 13, weight: .semibold, design: .default)

    /// Small caption (fine print, metadata)
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)

    // MARK: - Special Styles

    /// Movie title in lists/cards
    static let movieTitle = Font.system(size: 17, weight: .semibold, design: .default)

    /// Movie year/metadata
    static let movieMeta = Font.system(size: 13, weight: .medium, design: .default)

    /// Rating display
    static let rating = Font.system(size: 15, weight: .bold, design: .rounded)

    /// Large rating display
    static let ratingLarge = Font.system(size: 24, weight: .bold, design: .rounded)

    /// Achievement title
    static let achievementTitle = Font.system(size: 15, weight: .semibold, design: .default)

    /// News headline
    static let newsHeadline = Font.system(size: 17, weight: .semibold, design: .default)

    /// Button text
    static let button = Font.system(size: 17, weight: .semibold, design: .default)

    /// Small button text
    static let buttonSmall = Font.system(size: 15, weight: .medium, design: .default)

    /// Tab bar labels
    static let tabLabel = Font.system(size: 10, weight: .medium, design: .default)

    /// Navigation bar title
    static let navTitle = Font.system(size: 17, weight: .semibold, design: .default)

    /// Statistic label
    static let statLabel = Font.system(size: 13, weight: .medium, design: .default)

    /// Statistic value
    static let statValue = Font.system(size: 24, weight: .bold, design: .rounded)
}

// MARK: - Text Style View Modifiers

extension View {

    /// Apply hero title styling with optional glow effect
    func heroTitleStyle(withGlow: Bool = false) -> some View {
        self
            .font(Typography.heroTitle)
            .foregroundStyle(Color.primaryText)
            .modifier(GlowModifier(enabled: withGlow, color: .cageGold))
    }

    /// Apply hero number styling (for large stats)
    func heroNumberStyle(color: Color = .cageGold) -> some View {
        self
            .font(Typography.heroNumber)
            .foregroundStyle(color)
            .shadow(color: color.opacity(0.5), radius: 20)
    }

    /// Apply primary title styling
    func titleStyle() -> some View {
        self
            .font(Typography.title1)
            .foregroundStyle(Color.primaryText)
    }

    /// Apply section header styling
    func sectionHeaderStyle() -> some View {
        self
            .font(Typography.title2)
            .foregroundStyle(Color.primaryText)
    }

    /// Apply body text styling
    func bodyStyle() -> some View {
        self
            .font(Typography.body)
            .foregroundStyle(Color.primaryText)
    }

    /// Apply secondary body text styling
    func bodySecondaryStyle() -> some View {
        self
            .font(Typography.bodySecondary)
            .foregroundStyle(Color.secondaryText)
    }

    /// Apply caption styling
    func captionStyle() -> some View {
        self
            .font(Typography.caption1)
            .foregroundStyle(Color.tertiaryText)
    }

    /// Apply movie title styling (for cards/lists)
    func movieTitleStyle() -> some View {
        self
            .font(Typography.movieTitle)
            .foregroundStyle(Color.primaryText)
            .lineLimit(2)
    }

    /// Apply movie metadata styling (year, runtime, etc.)
    func movieMetaStyle() -> some View {
        self
            .font(Typography.movieMeta)
            .foregroundStyle(Color.secondaryText)
    }

    /// Apply rating display styling
    func ratingStyle(size: RatingSize = .regular) -> some View {
        self
            .font(size == .large ? Typography.ratingLarge : Typography.rating)
            .foregroundStyle(Color.cageGold)
    }

    /// Apply statistic label styling
    func statLabelStyle() -> some View {
        self
            .font(Typography.statLabel)
            .foregroundStyle(Color.secondaryText)
            .textCase(.uppercase)
    }

    /// Apply statistic value styling
    func statValueStyle() -> some View {
        self
            .font(Typography.statValue)
            .foregroundStyle(Color.cageGold)
    }

    /// Apply button text styling
    func buttonTextStyle() -> some View {
        self
            .font(Typography.button)
            .foregroundStyle(Color.primaryText)
    }
}

// MARK: - Supporting Types

enum RatingSize {
    case regular
    case large
}

/// Glow effect modifier for luminous text
struct GlowModifier: ViewModifier {
    let enabled: Bool
    let color: Color

    func body(content: Content) -> some View {
        if enabled {
            content
                .shadow(color: color.opacity(0.6), radius: 10)
                .shadow(color: color.opacity(0.3), radius: 20)
        } else {
            content
        }
    }
}

// MARK: - Dynamic Type Support

extension Typography {
    /// Get a font that scales with Dynamic Type
    static func scaledFont(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> Font {
        Font.system(size: size, weight: weight, design: design)
    }

    /// Preferred sizes for Dynamic Type categories
    enum DynamicSize {
        case extraSmall
        case small
        case medium
        case large
        case extraLarge
        case accessibility

        var bodySize: CGFloat {
            switch self {
            case .extraSmall: return 14
            case .small: return 15
            case .medium: return 17
            case .large: return 19
            case .extraLarge: return 21
            case .accessibility: return 28
            }
        }

        var captionSize: CGFloat {
            switch self {
            case .extraSmall: return 11
            case .small: return 12
            case .medium: return 13
            case .large: return 15
            case .extraLarge: return 17
            case .accessibility: return 22
            }
        }
    }
}

// MARK: - Text Line Height

extension View {
    /// Apply custom line spacing for improved readability
    func readableLineSpacing() -> some View {
        self.lineSpacing(4)
    }

    /// Apply tighter line spacing for compact displays
    func compactLineSpacing() -> some View {
        self.lineSpacing(2)
    }
}

// MARK: - Preview Helpers

#Preview("Typography Showcase") {
    ScrollView {
        VStack(alignment: .leading, spacing: 24) {
            Group {
                Text("Hero Title")
                    .heroTitleStyle()

                Text("97")
                    .heroNumberStyle()

                Text("Title 1 - Screen Headers")
                    .font(Typography.title1)

                Text("Title 2 - Section Headers")
                    .font(Typography.title2)

                Text("Title 3 - Subsections")
                    .font(Typography.title3)
            }

            Divider()

            Group {
                Text("Body - Primary content text that provides detailed information about movies and other content in the app.")
                    .bodyStyle()

                Text("Body Secondary - Supporting text and descriptions")
                    .bodySecondaryStyle()

                Text("Caption - Timestamps and labels")
                    .captionStyle()
            }

            Divider()

            Group {
                Text("Face/Off")
                    .movieTitleStyle()

                Text("1997 • 2h 18m")
                    .movieMetaStyle()

                HStack {
                    Text("4.5")
                        .ratingStyle()
                    Text("4.5")
                        .ratingStyle(size: .large)
                }
            }

            Divider()

            VStack(alignment: .leading) {
                Text("MOVIES WATCHED")
                    .statLabelStyle()
                Text("42")
                    .statValueStyle()
            }
        }
        .padding()
    }
    .background(Color.primaryBackground)
}
