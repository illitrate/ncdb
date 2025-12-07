# Onboarding & First Launch Experience

## Overview

The NCDB onboarding flow is designed to guide new users through initial setup while showcasing the app's unique features and Liquid Glass aesthetic. The flow takes 2-5 minutes depending on user interaction.

## Flow Structure
```
Launch App → Splash Screen → Welcome → Feature Highlights → TMDb API Key Setup 
→ Initial Data Seeding → Actor Selection → Ranking Tutorial → Permissions → Ready!
→ Main App
```

## Step-by-Step Flow

### Screen 1: Splash Screen
- **Duration:** 1-2 seconds
- **Purpose:** App initialization and branding
- **Visual:** NCDB icon with fade-in animation
- **Skip:** No (automatic progression)

### Screen 2: Welcome Screen
- **Purpose:** Introduction and value proposition
- **Features:**
  - App icon display
  - Welcome message
  - Four key features highlighted
  - "Get Started" CTA
- **Skip:** No
- **File Reference:** `OnboardingWelcomeView.swift`

### Screen 3-5: Feature Highlights (Swipeable)
- **Purpose:** Showcase three main features
- **Screens:**
  1. Track Every Film
  2. Rank Your Favorites (with carousel preview)
  3. Share & Discover
- **Navigation:** Swipe or "Next" button
- **Skip:** No (but quick to complete)
- **File Reference:** `OnboardingHighlightsView.swift`

### Screen 6: TMDb API Key Setup
- **Purpose:** Critical setup for app functionality
- **Features:**
  - API key input field
  - Validation on continue
  - Link to TMDb signup
  - Skip option (can add later in Settings)
- **Skip:** Yes (limited functionality warning)
- **File Reference:** `TMDbSetupView.swift`

### Screen 7: Initial Data Seeding
- **Purpose:** Load Nicolas Cage filmography
- **Process:**
  - Bundle 2 movies (Face/Off, Con Air)
  - Fetch complete filmography from TMDb
  - Download poster images
  - Build SwiftData database
- **Visual:** Progress indicator with status updates
- **Skip:** No (required for app functionality)
- **File Reference:** `DataSeedingView.swift`

### Screen 8: Actor Selection
- **Purpose:** Choose which actors to follow
- **Default:** Nicolas Cage (pre-selected, cannot deselect)
- **Features:**
  - Suggested actors list
  - Search for additional actors
  - Can add more later in Settings
- **Skip:** No (but Nic Cage already selected)
- **File Reference:** `ActorSelectionView.swift`

### Screen 9: Ranking Tutorial
- **Purpose:** Interactive demo of unique carousel ranking system
- **Features:**
  - Static demonstration
  - Interactive "Try It Now" mode
  - Swipe gesture explanation
- **Skip:** Yes
- **File Reference:** `RankingTutorialView.swift`

### Screen 10: Permissions
- **Purpose:** Request notification permissions
- **Features:**
  - Explanation of notification benefits
  - "Enable" or "Not Now" options
  - Can change later in Settings
- **Skip:** Yes
- **File Reference:** `PermissionsView.swift`

### Screen 11: Ready to Go!
- **Purpose:** Celebration and completion
- **Features:**
  - Success animation
  - Movie count display
  - "Enter NCDB" button
- **Skip:** No (final step)
- **File Reference:** `OnboardingReadyView.swift`

## Design Principles

### Visual Consistency
- **Background:** Deep black (#000000)
- **Accent Color:** Cage Gold (#FFD700)
- **Materials:** Ultra-thin frosted glass (`.ultraThinMaterial`)
- **Typography:** SF Pro Display (headers), SF Pro Text (body)
- **Corner Radius:** 16pt for primary elements, 12pt for secondary

### User Experience
- **Progressive Disclosure:** Information revealed step-by-step
- **Skippable Steps:** Non-critical steps can be skipped
- **Clear CTAs:** Cage Gold buttons guide users forward
- **Visual Feedback:** Animations and progress indicators throughout
- **Smart Defaults:** Nic Cage pre-selected, essential data bundled

### Accessibility
- **Minimum Touch Targets:** 44x44pt
- **Text Sizes:** Dynamic Type support
- **Color Contrast:** WCAG AA compliant
- **VoiceOver:** Fully labeled elements

## Technical Implementation

### State Management
```swift
@AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
```

### Flow Coordination
- **Coordinator Pattern:** `OnboardingCoordinator` manages navigation
- **Step Enum:** Tracks current onboarding screen
- **Animations:** Smooth transitions between screens

### Data Persistence
- **TMDb API Key:** Saved to Keychain
- **User Preferences:** Saved to UserDefaults
- **Movie Data:** Saved to SwiftData

## Completion Criteria

User has completed onboarding when:
1. ✅ Viewed welcome and feature highlights
2. ✅ TMDb API key validated (or skipped with acknowledgment)
3. ✅ Initial data seeding completed
4. ✅ At least one actor selected (Nic Cage default)
5. ✅ All remaining steps completed or explicitly skipped

## Post-Onboarding

After completion:
- `hasCompletedOnboarding` flag set to `true`
- User redirected to Home View
- All features fully accessible
- Settings available for modifications

## Testing Scenarios

### Happy Path
1. Complete all steps without skipping
2. Enter valid TMDb API key
3. Allow notifications
4. Complete tutorial

### Skip Path
1. Skip API key setup
2. Skip tutorial
3. Decline notifications
4. Verify limited functionality warnings

### Error Handling
1. Invalid API key entry
2. Network failure during seeding
3. TMDb API unavailable
4. Interrupted onboarding (app closed)

## Future Enhancements

- **Personalization:** Ask for favorite Cage film/era
- **Import:** Option to import existing data
- **Social:** Connect to social accounts
- **Achievements:** Award "First Steps" achievement on completion
