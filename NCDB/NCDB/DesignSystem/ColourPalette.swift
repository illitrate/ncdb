// NCDB Color Palette
// Define all colors used in the app

import SwiftUI

extension Color {
    // MARK: - Primary Colors
//    static let cageGold = Color("CageGold") // #FFD700

    // MARK: - Backgrounds
//    static let primaryBackground = Color("PrimaryBackground") // Deep black
//    static let secondaryBackground = Color("SecondaryBackground") // Slightly lighter black

    // MARK: - Text
    static let primaryText = Color.white
    static let secondaryText = Color.white.opacity(0.7)
    static let tertiaryText = Color.white.opacity(0.5)

    // MARK: - Glass Effects
    static let glassLight = Color.white.opacity(0.2)
    static let glassMedium = Color.white.opacity(0.1)
    static let glassDark = Color.black.opacity(0.3)

    // MARK: - Star Rating
    static let starFilled = Color.cageGold
    static let starEmpty = Color.white.opacity(0.3)

    // MARK: - Status Colors
    static let watched = Color.green
    static let unwatched = Color.gray
    static let favorite = Color.red

    // MARK: - Chart Colors
    static let chartPrimary = Color.cageGold
    static let chartSecondary = Color.blue.opacity(0.7)
    static let chartTertiary = Color.purple.opacity(0.7)
}

// MARK: - Color Assets
// Add these to Assets.xcassets:
/*
CageGold:
  Any Appearance: #FFD700

PrimaryBackground:
  Light: #1A1A1A
  Dark: #0A0A0A

SecondaryBackground:
  Light: #2D2D2D
  Dark: #1A1A1A
*/

