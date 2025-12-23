//
//  NewsView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SwiftData

/// Main news feed view
struct NewsView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \NewsArticle.publishedDate, order: .reverse) private var allArticles: [NewsArticle]

    @State private var isRefreshing = false
    @State private var selectedArticle: NewsArticle?
    @State private var showingSettings = false
    @State private var showAbout = false
    @State private var searchQuery = ""
    @State private var selectedSource: String?

    private let cacheManager = NewsCacheManager.shared
    private let scraperService = NewsScraperService.shared
    private let filterService = NewsFilterService.shared

    var body: some View {
        ZStack {
            if filteredArticles.isEmpty && !isRefreshing {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: Spacing.sm) {
                        ForEach(filteredArticles) { article in
                            NewsRow(article: article) {
                                selectedArticle = article
                                article.isRead = true
                                try? modelContext.save()
                            }
                        }
                    }
                    .padding()
                }
                .refreshable {
                    await refreshNews()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                NCDBLogoView {
                    showAbout = true
                }
            }

            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        Task { await refreshNews() }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)

                    Divider()

                    Button {
                        cacheManager.markAllAsRead(modelContext: modelContext)
                    } label: {
                        Label("Mark All as Read", systemImage: "envelope.open")
                    }
                    .disabled(unreadCount == 0)

                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }

                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .searchable(text: $searchQuery, prompt: "Search articles")
        .sheet(item: $selectedArticle) { article in
            NewsArticleDetailView(article: article)
        }
        .sheet(isPresented: $showingSettings) {
            NewsSettingsView()
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .task {
            // Initial load if needed
            if allArticles.isEmpty || cacheManager.shouldRefreshNews {
                await refreshNews()
            }
        }
    }

    // MARK: - Filtered Articles

    private var filteredArticles: [NewsArticle] {
        var articles = allArticles

        // Apply search query
        if !searchQuery.isEmpty {
            articles = filterService.search(articles, query: searchQuery)
        }

        // Apply source filter
        if let source = selectedSource {
            articles = filterService.filterBySource(articles, sources: [source])
        }

        return articles
    }

    private var unreadCount: Int {
        allArticles.filter { !$0.isRead }.count
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "newspaper")
                .font(.system(size: 64))
                .foregroundStyle(Color.secondaryText)

            Text("No News Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(Color.primaryText)

            Text("Pull to refresh or tap the button below to fetch the latest Nicolas Cage news")
                .font(.subheadline)
                .foregroundStyle(Color.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Spacing.xl)

            GlassButton(title: "Fetch News", style: .primary) {
                Task {
                    await refreshNews()
                }
            }
            .disabled(isRefreshing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func refreshNews() async {
        guard !isRefreshing else { return }

        isRefreshing = true

        do {
            let _ = await scraperService.fetchAllNews(modelContext: modelContext)
            cacheManager.recordFetch()

            HapticManager.shared.success()
        } catch {
            Logger.shared.error("Failed to refresh news: \(error)", category: .general)
            HapticManager.shared.error()
        }

        isRefreshing = false
    }
}

#Preview {
    NewsView()
        .modelContainer(for: NewsArticle.self, inMemory: true)
}
