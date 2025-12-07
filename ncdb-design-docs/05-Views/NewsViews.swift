//
//  NewsViews.swift
//  NCDB - Nicolas Cage Database
//
//  UI components for displaying news articles
//

import SwiftUI
import SwiftData

// MARK: - News Section (for Home View)

struct NewsSection: View {
    @Query(
        filter: #Predicate<NewsArticle> { !$0.isRead },
        sort: [
            SortDescriptor(\NewsArticle.relevanceScore, order: .reverse),
            SortDescriptor(\NewsArticle.publishedDate, order: .reverse)
        ]
    ) private var unreadArticles: [NewsArticle]
    
    @Query(
        sort: [
            SortDescriptor(\NewsArticle.publishedDate, order: .reverse)
        ]
    ) private var allArticles: [NewsArticle]
    
    @State private var showingAllNews = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Label("Cage News", systemImage: "newspaper.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.cageGold)
                
                Spacer()
                
                Button {
                    showingAllNews = true
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)
            
            // Recent Articles
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(unreadArticles.prefix(5)) { article in
                        NewsCardView(article: article)
                            .frame(width: 280)
                    }
                }
                .padding(.horizontal)
            }
            
            if unreadArticles.isEmpty {
                ContentUnavailableView(
                    "No New Articles",
                    systemImage: "newspaper",
                    description: Text("Check back later for Nicolas Cage news")
                )
                .frame(height: 200)
            }
        }
        .sheet(isPresented: $showingAllNews) {
            NewsListView()
        }
    }
}

// MARK: - News Card (for horizontal scroll)

struct NewsCardView: View {
    let article: NewsArticle
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Article Image (if available)
            if let imageURL = article.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(height: 140)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Source & Date
            HStack {
                Text(article.source)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.cageGold)
                
                Spacer()
                
                Text(article.publishedDate, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Title
            Text(article.title)
                .font(.headline)
                .lineLimit(3)
                .foregroundStyle(.primary)
            
            // Summary
            if let summary = article.summary {
                Text(summary)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .onTapGesture {
            openArticle()
        }
    }
    
    private func openArticle() {
        article.isRead = true
        try? modelContext.save()
        
        if let url = URL(string: article.url) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Full News List View

struct NewsListView: View {
    @Query private var articles: [NewsArticle]
    @State private var searchText = ""
    @State private var showOnlyUnread = false
    @State private var selectedSource: NewsSource?
    
    var filteredArticles: [NewsArticle] {
        articles.filter { article in
            let matchesSearch = searchText.isEmpty || 
                article.title.localizedCaseInsensitiveContains(searchText)
            let matchesUnread = !showOnlyUnread || !article.isRead
            let matchesSource = selectedSource == nil || 
                article.source == selectedSource?.rawValue
            
            return matchesSearch && matchesUnread && matchesSource
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredArticles) { article in
                    NewsRowView(article: article)
                }
            }
            .searchable(text: $searchText, prompt: "Search articles")
            .navigationTitle("Cage News")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle("Unread Only", isOn: $showOnlyUnread)
                        
                        Divider()
                        
                        Picker("Source", selection: $selectedSource) {
                            Text("All Sources").tag(NewsSource?(nil))
                            ForEach(NewsSource.allCases, id: \.self) { source in
                                Text(source.rawValue).tag(NewsSource?(source))
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
}

// MARK: - News Row (for list view)

struct NewsRowView: View {
    let article: NewsArticle
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Read indicator
            Circle()
                .fill(article.isRead ? Color.clear : Color.cageGold)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.headline)
                    .foregroundStyle(article.isRead ? .secondary : .primary)
                
                HStack {
                    Text(article.source)
                        .font(.caption)
                        .foregroundStyle(Color.cageGold)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(article.publishedDate, style: .relative)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            openArticle()
        }
        .swipeActions(edge: .leading) {
            Button {
                toggleRead()
            } label: {
                Label(
                    article.isRead ? "Unread" : "Read",
                    systemImage: article.isRead ? "envelope.badge" : "envelope.open"
                )
            }
            .tint(.blue)
        }
        .swipeActions(edge: .trailing) {
            Button {
                toggleFavorite()
            } label: {
                Label("Favorite", systemImage: article.isFavorite ? "star.fill" : "star")
            }
            .tint(Color.cageGold)
        }
    }
    
    private func openArticle() {
        article.isRead = true
        try? modelContext.save()
        
        if let url = URL(string: article.url) {
            UIApplication.shared.open(url)
        }
    }
    
    private func toggleRead() {
        article.isRead.toggle()
        try? modelContext.save()
    }
    
    private func toggleFavorite() {
        article.isFavorite.toggle()
        try? modelContext.save()
    }
}

// MARK: - News Settings View

struct NewsSettingsView: View {
    @Bindable var preferences: UserPreferences
    @Environment(NewsScraperService.self) private var newsService
    @State private var isRefreshing = false
    
    var body: some View {
        Form {
            Section("Refresh Frequency") {
                Picker("Update Schedule", selection: $preferences.newsScrapeFrequency) {
                    ForEach(NewsScrapeFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.rawValue).tag(frequency)
                    }
                }
                
                Toggle("Background Refresh", isOn: $preferences.enableBackgroundNewsRefresh)
            }
            
            Section("News Sources") {
                ForEach(NewsSource.allCases, id: \.self) { source in
                    Toggle(source.rawValue, isOn: Binding(
                        get: { preferences.enabledNewsSources.contains(source) },
                        set: { enabled in
                            if enabled {
                                preferences.enabledNewsSources.append(source)
                            } else {
                                preferences.enabledNewsSources.removeAll { $0 == source }
                            }
                        }
                    ))
                }
            }
            
            Section {
                Button {
                    refreshNews()
                } label: {
                    HStack {
                        Text("Refresh News Now")
                        Spacer()
                        if isRefreshing {
                            ProgressView()
                        }
                    }
                }
                .disabled(isRefreshing)
                
                if let lastScrape = newsService.lastScrapeDate {
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text(lastScrape, style: .relative)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("News Settings")
    }
    
    private func refreshNews() {
        isRefreshing = true
        Task {
            do {
                _ = try await newsService.scrapeNews()
            } catch {
                print("Refresh failed: \(error)")
            }
            isRefreshing = false
        }
    }
}
