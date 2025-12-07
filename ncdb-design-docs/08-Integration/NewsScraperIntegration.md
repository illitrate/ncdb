# News Scraper Integration Guide

## Setup Instructions

### 1. Add FeedKit Dependency

In your `Package.swift` or Xcode project:
```swift
dependencies: [
    .package(url: "https://github.com/nmdias/FeedKit.git", from: "9.1.2")
]
```

### 2. Configure Background Tasks

#### Info.plist
Add the background mode and task identifier:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>processing</string>
</array>
<key>BGTaskSchedulerPermittedIdentifiers</key>
<array>
    <string>com.yourapp.ncdb.newsrefresh</string>
</array>
```

#### AppDelegate
Register and handle background task:
```swift
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        // Register background task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.yourapp.ncdb.newsrefresh",
            using: nil
        ) { task in
            self.handleNewsRefresh(task: task as! BGAppRefreshTask)
        }
        
        return true
    }
    
    func handleNewsRefresh(task: BGAppRefreshTask) {
        // Schedule next refresh
        scheduleNewsRefresh()
        
        Task {
            do {
                // Perform scrape
                let newsService = NewsScraperService(
                    modelContext: /* inject from main context */,
                    userPreferences: /* inject */
                )
                _ = try await newsService.scrapeNews()
                
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    func scheduleNewsRefresh() {
        let request = BGAppRefreshTaskRequest(
            identifier: "com.yourapp.ncdb.newsrefresh"
        )
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 60 * 60) // 12 hours
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
}
```

### 3. Initialize Service in App
```swift
@main
struct NCDBApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var newsService: NewsScraperService?
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupNewsService()
                }
        }
    }
    
    private func setupNewsService() {
        // Initialize with model context and preferences
        // Make available to views via @Environment
    }
}
```

### 4. Add to Home View
```swift
struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Existing home content...
                
                NewsSection()  // Add news section
                
                // More home content...
            }
        }
    }
}
```

### 5. Add Settings Section

In your Settings view:
```swift
struct SettingsView: View {
    var body: some View {
        List {
            // Existing settings sections...
            
            NavigationLink("News") {
                NewsSettingsView()
            }
        }
    }
}
```

## Testing

### Test RSS Feeds
```swift
// In Xcode playground or test target
let parser = FeedParser(URL: URL(string: "https://news.google.com/rss/search?q=Nicolas+Cage")!)
parser.parseAsync { result in
    switch result {
    case .success(let feed):
        print("Successfully parsed: \(feed)")
    case .failure(let error):
        print("Failed: \(error)")
    }
}
```

### Test Background Refresh
Use Xcode's debug menu:
1. Run app on simulator/device
2. Xcode → Debug → Simulate Background Fetch
3. Check console for scraping activity

### Test Filtering
```swift
let testArticle = NewsArticle(
    url: "test",
    title: "Nicolas Cage Stars in New Film",
    summary: "The actor returns...",
    source: "Test",
    publishedDate: Date()
)

let isRelevant = NewsFilter.isRelevant(testArticle)
print("Article relevance: \(isRelevant)")
```

## Troubleshooting

### Feeds Not Loading
- Check network connectivity
- Verify feed URLs are accessible
- Check for rate limiting from source

### Background Refresh Not Working
- Ensure device is plugged in (iOS restriction)
- Check Background App Refresh is enabled in Settings
- Verify task identifier matches Info.plist

### Duplicate Articles
- NewsArticle model has `@Attribute(.unique)` on URL
- SwiftData automatically prevents duplicates

## Performance Considerations

- RSS parsing is async and non-blocking
- Multiple sources scraped concurrently
- Progress indicator shown during manual refresh
- Failed sources don't block others
- Old articles pruned automatically
