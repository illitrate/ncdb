# NCDB Design Documentation Export Guide
**How to Prepare Design Documents for Claude Code CLI**

---

## 📖 Overview

This guide explains how to export and organize all the design documentation from your project discussions so that Claude Code (command line interface) can effectively reference them when building your NCDB iOS app in Xcode.

---

## 🎯 Why This Structure Matters

Claude Code works best when:
1. **Documentation is modular** - Each file covers one specific aspect
2. **Code examples are complete** - Full working snippets, not fragments
3. **Files are well-named** - Descriptive names indicate content
4. **Structure is logical** - Related files are grouped together
5. **Context is provided** - Each file explains its purpose

---

## 📁 Recommended Folder Structure

Create this structure in a location accessible to both your terminal (for Claude Code) and Xcode:

```
 
```

---

## 📝 How to Create Each File

### Method 1: Manual Export from Claude.ai (Recommended)

For each conversation in your NCDB project:

1. **Open the conversation** in Claude.ai
2. **Find relevant code/specifications** in that chat
3. **Copy the content** (code blocks, design specs, etc.)
4. **Create a new file** in the appropriate folder
5. **Paste and format** with proper headers and context

**Example Workflow:**
```bash
# In your terminal:
cd ~/NCDB-Design-Docs/02-DataModels/
touch CoreModels.swift

# Then paste the SwiftData model code from the chat
```

---

### Method 2: Download Chat Transcripts

1. In Claude.ai, use the share/export feature (if available)
2. Download full conversation as text or markdown
3. Extract relevant sections into organized files
4. Clean up formatting and add structure

---

### Method 3: Ask Claude to Generate Export Files

In a new conversation, you can say:
> "Here's a conversation about [topic]. Please extract all the code examples and specifications into a well-structured markdown/swift file ready for export."

Then copy the output into your local files.

---

## 📋 Essential Files to Create

### Priority 1: Must-Have Files (Start Here)

#### `01-Overview/ProjectBrief.md`
```markdown
# NCDB Project Brief

## App Name
Nicolas Cage Database (NCDB)

## Purpose
Track, rate, review, and rank all Nicolas Cage movies with a beautiful Liquid Glass aesthetic.

## Target Platform
- iOS 26+
- iPhone (primary), iPad (secondary)
- Requires A13 Bionic or newer

## Core Features
- Movie tracking with TMDb integration
- 5-star rating system
- Written reviews
- Interactive ranking carousel
- Statistics dashboard
- News aggregation
- Achievements/gamification
- Social sharing
- Static website export
- iOS widgets

## Design Language
Liquid Glass aesthetic inspired by visionOS:
- Frosted glass materials
- Depth through layering
- Cage Gold accent color (#FFD700)
- Smooth animations
- Luminous data presentation

## Technical Stack
- SwiftUI
- SwiftData for persistence
- WidgetKit for widgets
- FeedKit for RSS parsing
- Native iOS frameworks
```

#### `02-DataModels/CoreModels.swift`
```swift
// NCDB Core Data Models
// Complete SwiftData model definitions for the app

import Foundation
import SwiftData

// MARK: - Production (Movie/TV Show)
@Model
final class Production {
    @Attribute(.unique) var id: UUID
    var title: String
    var releaseYear: Int
    var tmdbID: Int?
    
    // Type & Classification
    var productionType: ProductionType = .movie
    var genres: [String] = []
    
    // Visual Assets
    var posterPath: String?
    var backdropPath: String?
    
    // Metadata
    var plot: String?
    var director: String?
    var runtime: Int? // in minutes
    var budget: Int?
    var boxOffice: Int?
    
    // User Data
    var watched: Bool = false
    var dateWatched: Date?
    var userRating: Double?
    var review: String?
    var isFavorite: Bool = false
    var rankingPosition: Int?
    var watchCount: Int = 0
    
    // Relationships
    @Relationship(deleteRule: .cascade) var castMembers: [CastMember] = []
    @Relationship(deleteRule: .cascade) var watchEvents: [WatchEvent] = []
    @Relationship(deleteRule: .cascade) var externalRatings: [ExternalRating] = []
    @Relationship(inverse: \CustomTag.productions) var tags: [CustomTag] = []
    
    // Sync & Cache
    var metadataFetched: Bool = false
    var detailsCached: Bool = false
    var lastUpdated: Date?
    
    init(
        title: String,
        releaseYear: Int,
        tmdbID: Int? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.releaseYear = releaseYear
        self.tmdbID = tmdbID
        self.lastUpdated = Date()
    }
}

enum ProductionType: String, Codable {
    case movie = "Movie"
    case tvShow = "TV Show"
    case tvMovie = "TV Movie"
    case documentary = "Documentary"
}

// MARK: - Cast Member
@Model
final class CastMember {
    @Attribute(.unique) var id: UUID
    var name: String
    var character: String
    var order: Int // billing order
    var profilePath: String? // TMDb profile image
    
    // Relationship
    var production: Production?
    
    init(
        name: String,
        character: String,
        order: Int = 0
    ) {
        self.id = UUID()
        self.name = name
        self.character = character
        self.order = order
    }
}

// MARK: - Watch Event
@Model
final class WatchEvent {
    @Attribute(.unique) var id: UUID
    var watchedDate: Date
    var location: String? // e.g., "Home", "Cinema"
    var notes: String?
    var mood: String? // How you felt during/after
    
    // Relationship
    var production: Production?
    
    init(watchedDate: Date = Date()) {
        self.id = UUID()
        self.watchedDate = watchedDate
    }
}

// MARK: - External Rating
@Model
final class ExternalRating {
    @Attribute(.unique) var id: UUID
    var source: RatingSource
    var rating: Double
    var maxRating: Double
    var reviewCount: Int?
    var url: String?
    
    // Relationship
    var production: Production?
    
    init(
        source: RatingSource,
        rating: Double,
        maxRating: Double
    ) {
        self.id = UUID()
        self.source = source
        self.rating = rating
        self.maxRating = maxRating
    }
}

enum RatingSource: String, Codable {
    case imdb = "IMDb"
    case rottenTomatoes = "Rotten Tomatoes"
    case metacritic = "Metacritic"
    case letterboxd = "Letterboxd"
}

// MARK: - Custom Tag
@Model
final class CustomTag {
    @Attribute(.unique) var id: UUID
    var name: String
    var color: String // Hex color code
    var icon: String? // SF Symbol name
    var dateCreated: Date
    
    // Relationship
    var productions: [Production] = []
    
    init(name: String, color: String = "#FFD700") {
        self.id = UUID()
        self.name = name
        self.color = color
        self.dateCreated = Date()
    }
}
```

#### `02-DataModels/SupportingModels.swift`
```swift
// NCDB Supporting Data Models
// Models for news, achievements, exports, preferences

import Foundation
import SwiftData

// MARK: - News Article
@Model
final class NewsArticle {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var url: String
    
    var title: String
    var summary: String?
    var imageURL: String?
    var source: String
    var author: String?
    var publishedDate: Date
    var scrapedDate: Date
    
    var isRead: Bool = false
    var isFavorite: Bool = false
    var relevanceScore: Double = 0.0
    
    init(
        url: String,
        title: String,
        source: String,
        publishedDate: Date
    ) {
        self.id = UUID()
        self.url = url
        self.title = title
        self.source = source
        self.publishedDate = publishedDate
        self.scrapedDate = Date()
    }
}

// MARK: - Achievement
@Model
final class Achievement {
    @Attribute(.unique) var id: String
    var title: String
    var description: String
    var icon: String // SF Symbol
    var category: AchievementCategory
    var unlockedDate: Date?
    var isUnlocked: Bool = false
    var progress: Double = 0.0
    var requirement: Double = 1.0
    
    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        category: AchievementCategory
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
    }
}

enum AchievementCategory: String, Codable {
    case watchMilestones = "Watch Milestones"
    case ratings = "Ratings"
    case rankings = "Rankings"
    case variety = "Variety"
    case social = "Social"
    case completionist = "Completionist"
}

// MARK: - User Preferences
@Model
final class UserPreferences {
    @Attribute(.unique) var id: UUID
    
    // TMDb
    var tmdbAPIKey: String?
    var tmdbLanguage: String = "en-US"
    
    // Display
    var theme: String = "system" // "light", "dark", "system"
    var accentColor: String = "#FFD700"
    
    // Notifications
    var achievementNotifications: Bool = true
    var newsNotifications: Bool = true
    var reminderNotifications: Bool = false
    
    // Export
    var defaultExportFormat: String = "html"
    var includePosterImages: Bool = true
    
    // Privacy
    var includeReviewsInExport: Bool = true
    var shareStatistics: Bool = true
    
    init() {
        self.id = UUID()
    }
}

// MARK: - Export Template
@Model
final class ExportTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var type: ExportType
    var htmlTemplate: String?
    var cssStyles: String?
    var includeImages: Bool = true
    var includeRatings: Bool = true
    var includeReviews: Bool = true
    var dateCreated: Date
    
    init(name: String, type: ExportType) {
        self.id = UUID()
        self.name = name
        self.type = type
        self.dateCreated = Date()
    }
}

enum ExportType: String, Codable {
    case html = "HTML"
    case json = "JSON"
    case csv = "CSV"
}
```

#### `03-Services/TMDbService.swift`
```swift
// TMDb Service - API Integration
// Complete service for fetching movie data from The Movie Database

import Foundation

// MARK: - TMDb Service
@Observable
class TMDbService {
    // MARK: - Configuration
    private var apiKey: String
    private let baseURL = "https://api.themoviedb.org/3"
    private let imageBaseURL = "https://image.tmdb.org/t/p"
    private let nicolasCageID = 2963
    
    // MARK: - Networking
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // MARK: - Rate Limiting
    private var requestTimes: [Date] = []
    private let maxRequestsPerSecond = 4
    
    // MARK: - State
    var isLoading = false
    var lastError: TMDbError?
    
    init(apiKey: String) {
        self.apiKey = apiKey
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
        
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .formatted({
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter
        }())
    }
    
    // MARK: - Rate Limiting
    private func enforceRateLimit() async {
        let now = Date()
        requestTimes.removeAll { now.timeIntervalSince($0) > 1.0 }
        
        if requestTimes.count >= maxRequestsPerSecond {
            let oldestRequest = requestTimes.first!
            let waitTime = 1.0 - now.timeIntervalSince(oldestRequest)
            if waitTime > 0 {
                try? await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
        }
        
        requestTimes.append(Date())
    }
    
    // MARK: - Core API Methods
    
    /// Fetch all movies featuring Nicolas Cage
    func fetchNicolasCageMovies() async throws -> [TMDbMovie] {
        await enforceRateLimit()
        
        let endpoint = "\(baseURL)/person/\(nicolasCageID)/movie_credits"
        guard var components = URLComponents(string: endpoint) else {
            throw TMDbError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US")
        ]
        
        guard let url = components.url else {
            throw TMDbError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDbError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw TMDbError.apiError(statusCode: httpResponse.statusCode, message: "Request failed")
        }
        
        let credits = try decoder.decode(TMDbCreditsResponse.self, from: data)
        return credits.cast
    }
    
    /// Fetch detailed information about a specific movie
    func fetchMovieDetails(movieID: Int) async throws -> TMDbMovieDetails {
        await enforceRateLimit()
        
        let endpoint = "\(baseURL)/movie/\(movieID)"
        guard var components = URLComponents(string: endpoint) else {
            throw TMDbError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "append_to_response", value: "credits,images")
        ]
        
        guard let url = components.url else {
            throw TMDbError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TMDbError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw TMDbError.apiError(statusCode: httpResponse.statusCode, message: "Request failed")
        }
        
        return try decoder.decode(TMDbMovieDetails.self, from: data)
    }
    
    /// Get poster image URL for different sizes
    func posterURL(path: String, size: PosterSize = .w500) -> URL? {
        guard !path.isEmpty else { return nil }
        return URL(string: "\(imageBaseURL)/\(size.rawValue)\(path)")
    }
}

// MARK: - Error Handling
enum TMDbError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(statusCode: Int, message: String)
    case rateLimitExceeded
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API endpoint"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        case .apiError(let code, let message):
            return "API Error (\(code)): \(message)"
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please try again later."
        case .noData:
            return "No data received"
        }
    }
}

// MARK: - Response Models
struct TMDbCreditsResponse: Codable {
    let cast: [TMDbMovie]
}

struct TMDbMovie: Codable, Identifiable {
    let id: Int
    let title: String
    let releaseDate: String?
    let posterPath: String?
    let overview: String?
    let voteAverage: Double?
    
    var releaseYear: Int? {
        guard let dateString = releaseDate,
              let year = Int(dateString.prefix(4)) else {
            return nil
        }
        return year
    }
}

struct TMDbMovieDetails: Codable {
    let id: Int
    let title: String
    let overview: String?
    let releaseDate: String?
    let runtime: Int?
    let budget: Int?
    let revenue: Int?
    let posterPath: String?
    let backdropPath: String?
    let genres: [TMDbGenre]
    let credits: TMDbCredits?
}

struct TMDbGenre: Codable {
    let id: Int
    let name: String
}

struct TMDbCredits: Codable {
    let cast: [TMDbCastMember]
}

struct TMDbCastMember: Codable {
    let id: Int
    let name: String
    let character: String
    let order: Int
    let profilePath: String?
}

enum PosterSize: String {
    case w92 = "w92"
    case w154 = "w154"
    case w185 = "w185"
    case w342 = "w342"
    case w500 = "w500"
    case w780 = "w780"
    case original = "original"
}
```

---

### Priority 2: Important Supporting Files

#### `05-Views/LiquidGlassComponents.swift`
```swift
// Liquid Glass Design System Components
// Reusable SwiftUI views with frosted glass aesthetic

import SwiftUI

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 20
    
    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Glass Button
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var style: GlassButtonStyle = .primary
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.headline)
                }
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(style.backgroundColor)
                    .shadow(color: style.shadowColor, radius: 8, x: 0, y: 4)
            )
        }
    }
}

enum GlassButtonStyle {
    case primary
    case secondary
    case destructive
    
    var backgroundColor: Material {
        switch self {
        case .primary: return .thickMaterial
        case .secondary: return .thinMaterial
        case .destructive: return .ultraThinMaterial
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary: return Color("CageGold")
        case .secondary: return .white
        case .destructive: return .red
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .primary: return Color("CageGold").opacity(0.5)
        case .secondary: return .black.opacity(0.3)
        case .destructive: return .red.opacity(0.4)
        }
    }
}

// MARK: - Glass Frame (for posters/images)
struct GlassFrame<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16
    
    init(
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius + 4)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius + 4)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - Gold Badge
struct GoldBadge: View {
    let text: String
    let icon: String?
    
    init(_ text: String, icon: String? = nil) {
        self.text = text
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption.bold())
            }
            Text(text)
                .font(.caption.bold())
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color("CageGold"),
                            Color("CageGold").opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color("CageGold").opacity(0.6), radius: 8, x: 0, y: 4)
        )
    }
}
```

#### `07-DesignSystem/ColorPalette.swift`
```swift
// NCDB Color Palette
// Define all colors used in the app

import SwiftUI

extension Color {
    // MARK: - Primary Colors
//    static let cageGold = Color("CageGold") // #FFD700
    
    // MARK: - Backgrounds
    static let primaryBackground = Color("PrimaryBackground") // Deep black
    static let secondaryBackground = Color("SecondaryBackground") // Slightly lighter black
    
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
```

---

### Priority 3: Feature Specifications

Create these as markdown files describing the implementation:

#### `06-Features/OnboardingFlow.md`
#### `06-Features/RankingSystem.md`  
#### `06-Features/WidgetSpecifications.md`
#### `06-Features/AchievementsSystem.md`
#### `06-Features/SocialSharing.md`

---

## 🤖 Using These Files with Claude Code

### Step 1: Set Up Your Workspace

```bash
# Create the documentation directory
mkdir -p ~/NCDB-Design-Docs

# Initialize Git for version control
cd ~/NCDB-Design-Docs
git init
```

### Step 2: Populate the Files

Copy all the code and specifications from your Claude.ai project conversations into the appropriate files following the structure above.

### Step 3: Create a Master README

Create `~/NCDB-Design-Docs/README.md`:

```markdown
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
```

### Step 4: Using with Claude Code

When you start working with Claude Code:

```bash
# Navigate to your Xcode project
cd ~/XcodeProjects/NCDB

# Start Claude Code with design docs context
# (Syntax may vary based on Claude Code CLI version)
claude-code

# Then in your conversation with Claude Code:
```

**Example prompts:**

> "I'm building the NCDB iOS app. I have complete design documentation in ~/NCDB-Design-Docs/. Let's start by implementing the SwiftData models from 02-DataModels/CoreModels.swift"

> "Reference the TMDbService.swift file in my design docs and help me implement the API integration with proper error handling and rate limiting"

> "Using the Liquid Glass components defined in my design docs, let's build the movie detail view"

> "Check the OnboardingFlow.md spec and help me create the onboarding coordinator"

---

## 💡 Pro Tips

### 1. Keep Documentation Updated

As you make changes during development:
```bash
cd ~/NCDB-Design-Docs
git add .
git commit -m "Updated data models with new properties"
```

### 2. Use Clear File Names

Good: `TMDbService.swift`, `LiquidGlassComponents.swift`  
Bad: `service.swift`, `components.swift`

### 3. Include Context in Each File

Start each file with comments explaining:
- What this file contains
- How it fits into the overall architecture
- Any dependencies or related files

### 4. Link Related Files

In markdown files, reference related code:

```markdown
## Implementation

See `03-Services/TMDbService.swift` for the API integration.
See `02-DataModels/CoreModels.swift` for the Production model.
```

### 5. Include Examples

For complex features, include usage examples:

```swift
// Example usage:
let service = TMDbService(apiKey: "your-api-key")
let movies = try await service.fetchNicolasCageMovies()
```

### 6. Create Quick Reference

Make a `QUICKREF.md` with common patterns:

```markdown
# Quick Reference

## Creating a new glass card:
\`\`\`swift
GlassCard {
    VStack {
        Text("Content")
    }
}
\`\`\`

## Fetching TMDb data:
\`\`\`swift
let service = TMDbService(apiKey: apiKey)
let movies = try await service.fetchNicolasCageMovies()
\`\`\`
```

---

## 📊 Verification Checklist

Before starting development with Claude Code, verify you have:

- [ ] All SwiftData models exported
- [ ] Complete service layer code (TMDb, Cache, News, Export)
- [ ] Liquid Glass component definitions
- [ ] Color palette and design tokens
- [ ] Feature specifications (Onboarding, Ranking, Widgets, etc.)
- [ ] View architecture documented
- [ ] Integration details (API keys, FTP, etc.)
- [ ] Testing strategy outlined
- [ ] README with navigation guide
- [ ] All files organized in logical structure

---

## 🔄 Workflow: Claude.ai → Local Files → Claude Code → Xcode

**The Complete Process:**

1. **Design in Claude.ai** (What you've done)
   - Discuss features and specifications
   - Refine designs and code structures

2. **Export to Local Files** (Do this now)
   - Copy code/specs into organized structure
   - Add context and documentation
   - Commit to Git

3. **Develop with Claude Code** (Next step)
   - Reference design docs in conversation
   - Generate implementation code
   - Review and iterate

4. **Build in Xcode** (Final step)
   - Copy generated code into Xcode
   - Use Xcode AI for refinements
   - Build, test, and deploy

---

## 🎯 Summary

**Best practices for Claude Code usage:**

✅ **Modular** - One file per concern  
✅ **Complete** - Full working examples  
✅ **Documented** - Context and purpose explained  
✅ **Organized** - Logical folder structure  
✅ **Versioned** - Use Git for tracking  
✅ **Referenced** - Easy to cite specific files  

With this structure, Claude Code can:
- Quickly understand your project
- Reference specific components
- Generate consistent code
- Maintain your design decisions
- Build incrementally with context

---

**Next Steps:** Start populating these files with content from your project conversations, then you'll be ready to begin development with Claude Code!
