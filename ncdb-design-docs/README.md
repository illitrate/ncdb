# NCDB Design Documentation

Complete design specifications for the Nicolas Cage Database iOS app.

## How to Use This Documentation

This repository contains all design decisions, code examples, and specifications
for building the NCDB iOS app with SwiftUI and iOS 26.

### For Claude Code CLI:

When starting a development session, reference these files:

\`\`\`bash
# Start Claude Code in your Xcode project directory
cd ~/YourXcodeProject/NCDB

# Reference specific design docs
claude-code --context ~/NCDB-Design-Docs/
\`\`\`

### File Organization:

- **01-Overview**: High-level project information
- **02-DataModels**: Complete SwiftData models
- **03-Services**: API services and managers
- **04-ViewModels**: Observable view models
- **05-Views**: SwiftUI views and components
- **06-Features**: Feature specifications and flows
- **07-DesignSystem**: Colors, typography, styling
- **08-Integration**: External integrations
- **09-Testing**: Test strategies and scenarios

### Key Files to Reference First:

1. `01-Overview/ProjectBrief.md` - Understand the project
2. `02-DataModels/CoreModels.swift` - Data structure
3. `03-Services/TMDbService.swift` - API integration
4. `05-Views/LiquidGlassComponents.swift` - UI components
5. `07-DesignSystem/ColorPalette.swift` - Design tokens

## Design Philosophy

The app uses the Liquid Glass aesthetic inspired by visionOS:
- Frosted glass materials with depth
- Cage Gold (#FFD700) as accent color
- Smooth animations and transitions
- Luminous data presentation

## Architecture

- **Pattern**: MVVM (Model-View-ViewModel)
- **UI Framework**: SwiftUI
- **Data Persistence**: SwiftData
- **Minimum iOS**: 26.0
- **Target Devices**: iPhone (primary), iPad (secondary)


Summary of Files in this folder and subfolders:

| File Name                      | Folder            | Purpose                                |
|--------------------------------|-------------------|----------------------------------------|
| NewsScraperService.swift       | 03-Services/      | Main scraping logic                    |
| NewsSource.swift               | 03-Services/      | Source enumeration                     |
| NewsArticle.swift              | 02-DataModels/    | Article data model                     |
| SupportingModels.swift         | 02-DataModels/    | Add preferences (update existing)      |
| NewsViews.swift                | 05-Views/         | All UI components                      |
| NewsScraperSystem.md           | 06-Features/      | Feature documentation                  |
| NewsScraperIntegration.md      | 08-Integration/   | Setup guide                            |
| OnboardingFlow.md              | 06-Features/      | Complete onboarding documentation      |
| OnboardingCoordinator.swift    | 05-Views/         | Main flow coordinator and navigation   |
| OnboardingSplashView.swift     | 05-Views/         | Initial splash screen with branding    |
| OnboardingWelcomeView.swift    | 05-Views/         | Welcome screen with feature highlights |
| OnboardingHighlightsView.swift | 05-Views/         | Swipeable feature showcase (3 screens) |
| TMDbSetupView.swift            | 05-Views/         | API key input and validation           |
| DataSeedingView.swift          | 05-Views/         | Initial filmography loading screen     |
| ActorSelectionView.swift       | 05-Views/         | Choose actors to follow                |
| RankingTutorialView.swift      | 05-Views/         | Interactive carousel tutorial          |
| PermissionsView.swift          | 05-Views/         | Notification permissions request       |
| OnboardingReadyView.swift      | 05-Views/         | Completion celebration screen          |
| ColourExtension.swift          | 07-DesignSystem/  | Hex color support utility              |
