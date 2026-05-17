<p align="center">
  <img src="https://github.com/illitrate/ncdb/blob/main/Docs/App%20Icon%20Small.jpeg?raw=true" width="200" alt="NCDB App Icon"/>
</p>

<h1 align="center">NCDB — Nicolas Cage Database</h1>

<p align="center">
  The ultimate iOS companion app for tracking, ranking, and celebrating every Nicolas Cage performance.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS_26+-black?style=flat-square&logo=apple&logoColor=white" alt="iOS 26+"/>
  <img src="https://img.shields.io/badge/Swift-6-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift"/>
  <img src="https://img.shields.io/badge/SwiftUI-Liquid_Glass-007AFF?style=flat-square&logo=swift&logoColor=white" alt="SwiftUI"/>
  <img src="https://img.shields.io/badge/SwiftData-Persistence-34C759?style=flat-square" alt="SwiftData"/>
</p>

---

## What is NCDB?

NCDB is a native iOS app built with SwiftUI and Apple's Liquid Glass design language. It pulls Nicolas Cage's complete filmography from TMDb and gives you a rich set of tools to track what you've watched, rate and review every film, build your personal rankings, earn achievements, and stay up to date with the latest Cage news — all wrapped in a dark-and-gold aesthetic that feels right at home on iOS 26.

<p align="center">
  <img src="https://github.com/illitrate/ncdb/blob/main/Docs/NCDB%20About%20Screen%20Medium.jpeg?raw=true" width="200" alt="NCDB About Screen"/>
</p>

---

## Features

### Dashboard at a Glance

<img src="https://github.com/illitrate/ncdb/blob/main/Docs/NCDB%20Home%20Screen%20Medium.jpeg?raw=true" width="150" align="right" alt="NCDB Home Screen"/>

- Personalised home screen with time-of-day greeting
- Quick stats: films watched, average rating, total runtime, completion percentage
- Recently watched carousel, latest achievements, watchlist preview, and breaking news — all on one screen

<br clear="right"/>

### Browse the Complete Filmography

<img src="https://github.com/illitrate/ncdb/blob/main/Docs/NCDB%20Movie%20list%20Medium.jpeg?raw=true" width="150" align="right" alt="NCDB Movie List"/>

- Every Nicolas Cage film, TV appearance, and documentary in one place, sourced live from **TMDb**
- Grid or list view with real-time search and advanced filtering by genre, year, type, and watch status
- Full film details: plot, runtime, budget, box office, cast, director, and external ratings
- Smart content filtering hides non-acting appearances and documentaries by default, with manual overrides

<br clear="right"/>

### Track Your Watching
- Mark films as watched and log detailed watch events with date, location, companions, mood, and notes
- Support for rewatches — track every viewing separately
- Star ratings (0–5 with half-star precision) and written reviews for each film
- Save your favourite quotes from any film
- Watchlist view shows everything you haven't seen yet

### Rank Your Favourites

<img src="https://github.com/illitrate/ncdb/blob/main/Docs/NCDB%20Rankings%20view%20Medium.jpeg?raw=true" width="150" align="right" alt="NCDB Rankings View"/>

- Interactive **ranking carousel** with 3D parallax card effects and drag-and-drop reordering
- Podium display highlights your top 3
- Bidirectional sync between ratings and ranking positions — rate a film and it auto-slots into your rankings
- Switch between carousel and list views
- Share your rankings as an image or text

<br clear="right"/>

### Earn Achievements

<img src="https://github.com/illitrate/ncdb/blob/main/Docs/NCDB%20Achievments%20Medium.jpeg?raw=true" width="150" align="right" alt="NCDB Achievements"/>

- **50+ achievements** across six categories: Watching, Rating, Streak, Ranking, Collection, and Special
- Real-time progress tracking with visual indicators on locked badges
- Toast notifications when you unlock something new
- Achievements like *First Watch*, *Marathon Runner* (5 in a week), *Completionist*, *Harsh Critic*, and hidden easter eggs

<br clear="right"/>

### Stay Current with News
- Aggregated news feed from **7 industry sources**: The Hollywood Reporter, Variety, Deadline, IndieWire, /Film, The Wrap, and Google News
- Keyword filtering ensures only Nicolas Cage–relevant articles appear
- Relevance scoring ranks the most important stories first
- Mark articles as read or favourite, search by keyword, filter by source
- Configurable background refresh (manual, daily, twice daily, weekly)

### Statistics and Analytics
- Genre distribution, rating breakdown, watch timeline, and production type charts powered by Swift Charts
- Track your total runtime, favourite genres, and how your tastes evolve over time
- All stats respect your content filter settings

### Export Your Collection
- **Website export wizard**: generate a complete static HTML website from your collection with customisable templates, optional poster images, and automatic CSS styling
- **FTP auto-publish**: upload your generated site directly to a web server
- **JSON/CSV export** of your full database for backup or analysis
- Privacy controls let you exclude reviews from exports

### Personalise Everything
- TMDb API key management with sync status
- Content filtering toggles (non-acting appearances, documentaries) with per-item overrides
- Haptic feedback, notification preferences, and cache management
- Full data reset and re-onboarding options

---

## Architecture

| Layer | Technology |
|---|---|
| **UI** | SwiftUI with Liquid Glass design components |
| **Persistence** | SwiftData (SQLite) with automatic migration |
| **Architecture** | MVVM with `@Observable` ViewModels |
| **Networking** | URLSession with rate limiting (4 req/sec) |
| **Image Caching** | Custom memory + disk cache with `CachedAsyncImage` |
| **News** | RSS feed parsing from 7 sources with relevance scoring |
| **Security** | Keychain for credentials, no plaintext secrets |
| **Concurrency** | `@MainActor` isolation, Swift structured concurrency |

---

## Design

NCDB follows a **dark-and-gold** visual language inspired by cinema:

- **Cage Gold** (`#FFD700`) accents against deep black backgrounds
- Glass morphism effects with blur and translucency
- 3D card rotations and parallax in the ranking carousel
- Spring animations and smooth transitions throughout
- Forced dark mode for a consistent theatrical feel

---

## Getting Started

1. **Clone the repo**
   ```bash
   git clone https://github.com/illitrate/ncdb.git
   ```
2. **Open in Xcode** — requires Xcode with iOS 26 SDK support
3. **Build and run** on a simulator or device running iOS 26+
4. **Complete onboarding** — you'll be prompted to enter a [TMDb API key](https://www.themoviedb.org/settings/api) (free)
5. The app will fetch Nicolas Cage's full filmography and you're ready to go

---

## Requirements

- iOS 26.0+
- Xcode (latest with iOS 26 SDK)
- A free [TMDb API key](https://www.themoviedb.org/settings/api)

---

## Data Attribution

Movie metadata, posters, and images are provided by [The Movie Database (TMDb)](https://www.themoviedb.org/). This product uses the TMDb API but is not endorsed or certified by TMDb.

---

## License

This project is provided as-is for personal and educational use.
