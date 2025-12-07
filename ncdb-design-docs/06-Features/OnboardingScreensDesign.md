Screen-by-Screen Design
Screen 1: Splash Screen
Duration: 1-2 seconds (or until app initialization completes)
Visual Design:
┌─────────────────────────────┐
│                             │
│                             │
│         [NCDB Icon]         │
│       Film Reel with        │
│      Cage Silhouette        │
│                             │
│           NCDB              │
│     (fade in animation)     │
│                             │
│                             │
│                             │
└─────────────────────────────┘
Styling:

Black background (#000000)
Icon: 120pt, centered
App name: SF Pro Display Bold, 48pt, Cage Gold (#FFD700)
Subtle fade-in animation
No interaction needed

[see /05-Views/OnboardingSplashView.swift for suggested code]


Screen 2: Welcome Screen
Visual Design:
┌─────────────────────────────┐
│                             │
│         [NCDB Icon]         │
│          (smaller)          │
│                             │
│     Welcome to NCDB         │
│                             │
│  Your Personal Nicolas Cage │
│    Movie Tracking Vault     │
│                             │
│   • Track every Cage film   │
│   • Rank your favorites     │
│   • Share your reviews      │
│   • Discover hidden gems    │
│                             │
│                             │
│    [Get Started Button]     │
│                             │
└─────────────────────────────┘
Styling:

Background: Deep black with subtle gradient
Frosted card containing content (Liquid Glass material)
Icon: 80pt at top
Title: SF Pro Display Bold, 34pt, White
Subtitle: SF Pro Text Regular, 17pt, White 70% opacity
Bullet points: SF Pro Text Medium, 15pt, Cage Gold
Button: Filled, Cage Gold background, rounded corners (16pt radius)

[see /05-Views/OnboardingWelcomeView.swift for suggested code]

### **Screen 3-5: Feature Highlights (Swipeable)**

**Three screens showing key features:**

#### **Highlight 1: Track Every Film**
```
┌─────────────────────────────┐
│                             │
│    [Illustration/Icon]      │
│     Movie posters grid      │
│                             │
│    Track Every Film         │
│                             │
│  Browse Nic Cage's entire   │
│  filmography from The Movie │
│  Database. Mark films as    │
│  watched, add ratings, and  │
│  write personal reviews.    │
│                             │
│                             │
│         ○ ● ○               │
│                             │
│         [Next]              │
└─────────────────────────────┘
```

#### **Highlight 2: Rank Your Favorites**
```
┌─────────────────────────────┐
│                             │
│    [Illustration/Icon]      │
│   Carousel with drag UI     │
│                             │
│   Rank Your Favorites       │
│                             │
│  Create custom rankings     │
│  with our unique carousel   │
│  interface. Drag and drop   │
│  to reorder. Compare films  │
│  side by side.              │
│                             │
│                             │
│         ○ ○ ●               │
│                             │
│         [Next]              │
└─────────────────────────────┘
```

#### **Highlight 3: Share & Discover**
```
┌─────────────────────────────┐
│                             │
│    [Illustration/Icon]      │
│    Share/stats graphics     │
│                             │
│   Share & Discover          │
│                             │
│  Export your collection to  │
│  the web. Share reviews on  │
│  social media. Discover     │
│  hidden gems and stay       │
│  updated with Cage news.    │
│                             │
│                             │
│         ○ ○ ○               │
│                             │
│    [Get Started]            │
└─────────────────────────────┘

[see /05-Views/OnboardingHighlightsView.swift for suggested code]


### **Screen 6: TMDb API Key Setup**

**Critical screen** - without this, the app can't function.

**Visual Design:**
```
┌─────────────────────────────┐
│                             │
│      [TMDb Logo Icon]       │
│                             │
│   Connect to The Movie      │
│        Database             │
│                             │
│  NCDB uses TMDb to fetch    │
│  movie data, posters, and   │
│  details. You'll need a     │
│  free API key to continue.  │
│                             │
│  ┌─────────────────────┐   │
│  │ [Text Field]        │   │
│  │ Enter API Key       │   │
│  └─────────────────────┘   │
│                             │
│  [Don't have a key?]        │
│   → Get One Free            │
│                             │
│                             │
│      [Continue] [Skip]      │
│                             │
└─────────────────────────────┘
Two Paths:

Enter API Key → Validates → Continues
"Get One Free" → Opens Safari to TMDb signup → User copies key → Returns to app

[see /05-Views/TMDbSetupView.swift for suggested code]


### **Screen 7: Initial Data Seeding**

**What happens:**
- App bundles 2 movies (Face/Off, Con Air) for immediate use
- Fetches Nicolas Cage's complete filmography from TMDb
- Shows progress with visual feedback

**Visual Design:**
```
┌─────────────────────────────┐
│                             │
│                             │
│      [Animated Icon]        │
│     Film reels spinning     │
│                             │
│   Loading Your Collection   │
│                             │
│  ████████████░░░░░░░░       │
│        65% Complete         │
│                             │
│  Fetching Nicolas Cage      │
│     filmography...          │
│                             │
│   • Found 127 productions   │
│   • Downloading posters     │
│   • Building your vault     │
│                             │
│                             │
└─────────────────────────────┘

[see /05-Views/DataSeedingView.swift for suggested code]


## **Screen 8: Actor Selection**

**Default:** Nic Cage pre-selected
**Optional:** Add other actors to follow

**Visual Design:**
```
┌─────────────────────────────┐
│                             │
│   Choose Actors to Follow   │
│                             │
│  ┌───────────────────────┐  │
│  │ [✓] Nicolas Cage      │  │
│  │     Default actor     │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ [ ] Jessica Alba      │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │ [ ] Jorma Tommiala    │  │
│  └───────────────────────┘  │
│                             │
│  [+ Add Another Actor]      │
│                             │
│  You can always add more    │
│  actors later in Settings.  │
│                             │
│       [Continue]            │
│                             │
└─────────────────────────────┘

[see /05-Views/ActorSelectionView.swift for suggested code]



### **Screen 9: Ranking Tutorial**

**Interactive demo** of the unique carousel ranking system.

**Visual Design:**
```
┌─────────────────────────────┐
│                             │
│   Master the Ranking        │
│       Carousel              │
│                             │
│  ┌─────┐  ┌─────┐  ┌─────┐  │
│  │ #2  │  │ #1  │  │ #3  │  │
│  │ Con │  │Face/│  │ The │  │
│  │ Air │  │ Off │  │ Rock│  │
│  └─────┘  └─────┘  └─────┘  │
│                             │
│  [< Swipe to reorder >]     │
│                             │
│  Try it yourself:           │
│  Swipe left or right to     │
│  change rankings. The       │
│  center film is always #1!  │
│                             │
│                             │
│       [Try It Now]          │
│         [Skip]              │
│                             │
└─────────────────────────────┘

[see /05-Views/RankingTutorialView.swift for suggested code]


### **Screen 10: Permissions**

**Optional:** Request notification permissions for new movie alerts, etc.

**Visual Design:**
```
┌─────────────────────────────┐
│                             │
│      [Bell Icon]            │
│                             │
│  Stay Updated with          │
│    Notifications            │
│                             │
│  Get notified when:         │
│                             │
│  • New Cage films announced │
│  • Important news breaks    │
│  • You hit milestones       │
│                             │
│  You can change this        │
│  anytime in Settings.       │
│                             │
│                             │
│   [Enable Notifications]    │
│       [Not Now]             │
│                             │
└─────────────────────────────┘

[see /05-Views/PermissionsView.swift for suggested code]


### **Screen 11: Ready to Go!**

**Final celebration screen** before entering the app.

**Visual Design:**
```
┌─────────────────────────────┐
│                             │
│                             │
│      [Success Icon]         │
│     Checkmark + Sparkles    │
│                             │
│      You're All Set!        │
│                             │
│  Your vault is ready with   │
│  127 Nicolas Cage films.    │
│                             │
│  Start watching, reviewing, │
│  and ranking your favorite  │
│  Cage classics!             │
│                             │
│                             │
│    [Enter NCDB] →           │
│                             │
│                             │
└─────────────────────────────┘


[see /05-Views/OnboardingReadyView.swift for suggested code]




