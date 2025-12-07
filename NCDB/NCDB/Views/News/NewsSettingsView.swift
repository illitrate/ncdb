//
//  NewsSettingsView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SwiftData

/// News settings and preferences view
struct NewsSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var newsNotificationsEnabled = UserDefaults.standard.bool(forKey: "newsNotificationsEnabled")
    @State private var backgroundRefreshEnabled = UserDefaults.standard.bool(forKey: "backgroundRefreshEnabled")
    @State private var showingClearConfirmation = false

    private let cacheManager = NewsCacheManager.shared
    private let backgroundTaskManager = BackgroundTaskManager.shared

    var body: some View {
        NavigationStack {
            Form {
                // Notifications Section
                Section("Notifications") {
                    Toggle("News Notifications", isOn: $newsNotificationsEnabled)
                        .onChange(of: newsNotificationsEnabled) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "newsNotificationsEnabled")

                            if newValue {
                                Task {
                                    await NotificationManager.shared.requestPermission()
                                }
                            }
                        }

                    if newsNotificationsEnabled {
                        Text("Get notified when new Nicolas Cage news is available")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Background Refresh Section
                Section("Background Refresh") {
                    Toggle("Auto Refresh", isOn: $backgroundRefreshEnabled)
                        .onChange(of: backgroundRefreshEnabled) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "backgroundRefreshEnabled")

                            if newValue {
                                backgroundTaskManager.scheduleNewsRefresh()
                            } else {
                                backgroundTaskManager.cancelAllTasks()
                            }
                        }

                    if backgroundRefreshEnabled {
                        Text("Automatically fetch new articles in the background")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Cache Section
                Section("Cache") {
                    let stats = cacheManager.getCacheStats(modelContext: modelContext)

                    LabeledContent("Total Articles", value: "\(stats.totalArticles)")
                    LabeledContent("Unread Articles", value: "\(stats.unreadArticles)")
                    LabeledContent("Last Updated", value: stats.formattedCacheAge)

                    Button("Clear All Articles") {
                        showingClearConfirmation = true
                    }
                    .foregroundStyle(.red)
                }

                // About Section
                Section("About") {
                    LabeledContent("Sources", value: "5 news sources")

                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Sources:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("• The Hollywood Reporter\n• Variety\n• Deadline\n• IndieWire\n• Collider")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("News Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "Clear All Articles",
                isPresented: $showingClearConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear", role: .destructive) {
                    cacheManager.clearAllArticles(modelContext: modelContext)
                    HapticManager.shared.success()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will remove all cached news articles. This cannot be undone.")
            }
        }
    }
}

#Preview {
    NewsSettingsView()
        .modelContainer(for: NewsArticle.self, inMemory: true)
}
