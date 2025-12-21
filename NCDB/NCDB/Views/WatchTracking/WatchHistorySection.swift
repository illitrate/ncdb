//
//  WatchHistorySection.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Timeline section showing watch history for a movie
struct WatchHistorySection: View {
    let production: Production

    @State private var watchEvents: [WatchEvent] = []
    @State private var showingDetailFor: WatchEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Watch History")
                    .font(.headline)
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Text("\(watchEvents.count) \(watchEvents.count == 1 ? "time" : "times")")
                    .font(.caption)
                    .foregroundStyle(Color.secondaryText)
            }

            if watchEvents.isEmpty {
                Text("No watch history yet")
                    .font(.subheadline)
                    .foregroundStyle(Color.tertiaryText)
                    .padding(.vertical, Spacing.sm)
            } else {
                VStack(spacing: Spacing.xs) {
                    ForEach(watchEvents) { event in
                        WatchEventRow(event: event)
                            .onTapGesture {
                                showingDetailFor = event
                            }
                    }
                }
            }
        }
        .onAppear {
            loadWatchEvents()
        }
        .sheet(item: $showingDetailFor) { event in
            WatchEventDetailView(event: event, onDelete: {
                loadWatchEvents()
            })
        }
    }

    private func loadWatchEvents() {
        watchEvents = WatchHistoryManager.shared.getWatchEvents(for: production)
    }
}

struct WatchEventRow: View {
    let event: WatchEvent

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Compact date and time
            HStack(spacing: 4) {
                Text(event.watchedAt.formatted(.dateTime.day()))
                    .font(.caption.bold())
                    .foregroundStyle(Color.cageGold)

                Text(event.watchedAt.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2)
                    .foregroundStyle(Color.secondaryText)

                Text(event.watchedAt.formatted(.dateTime.year()))
                    .font(.caption2)
                    .foregroundStyle(Color.tertiaryText)

                Text("/")
                    .font(.caption2)
                    .foregroundStyle(Color.tertiaryText)

                Text(event.watchedAt.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundStyle(Color.tertiaryText)
            }

            // Rating if available
            if let rating = event.rating, rating > 0 {
                HStack(spacing: 1) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.cageGold)
                    Text(String(format: "%.1f", rating))
                        .font(.caption2)
                        .foregroundStyle(Color.cageGold)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(.vertical, Spacing.xxs)
        .padding(.horizontal, Spacing.sm)
        .background(Color.glassLight)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
