//
//  RankingsWidgetIntent.swift
//  NCDB
//
//  Configuration for the Top Rankings widget. Shared with the widget extension.
//

import AppIntents
import Foundation

// MARK: - Ranking Display Style

enum RankingWidgetStyle: String, AppEnum {

    case topThree
    case topFive
    case numberOneOnly

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Ranking Style")

    static let caseDisplayRepresentations: [RankingWidgetStyle: DisplayRepresentation] = [
        .numberOneOnly: DisplayRepresentation(title: "Number One Only"),
        .topThree: DisplayRepresentation(title: "Top Three"),
        .topFive: DisplayRepresentation(title: "Top Five")
    ]

    var count: Int {
        switch self {
        case .numberOneOnly: return 1
        case .topThree: return 3
        case .topFive: return 5
        }
    }
}

// MARK: - Configuration Intent

/// Lets the user long-press the widget and choose what it shows — the whole
/// point of AppIntentConfiguration over the old StaticConfiguration.
struct RankingsWidgetConfiguration: WidgetConfigurationIntent {

    static let title: LocalizedStringResource = "Top Rankings"
    static let description = IntentDescription("Choose how much of your ranking the widget shows.")

    @Parameter(title: "Show", default: .topThree)
    var style: RankingWidgetStyle

    @Parameter(title: "Show Posters", default: true)
    var showPosters: Bool

    init() {}
}
