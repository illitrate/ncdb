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
            // Date indicator
            VStack(spacing: Spacing.xxxs) {
                Text(event.watchedAt.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption2)
                    .foregroundStyle(Color.tertiaryText)

                Text(event.watchedAt.formatted(.dateTime.day()))
                    .font(.headline)
                    .foregroundStyle(Color.cageGold)

                Text(event.watchedAt.formatted(.dateTime.year()))
                    .font(.caption2)
                    .foregroundStyle(Color.tertiaryText)
            }
            .frame(width: 50)

            // Event details
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                HStack {
                    if let rating = event.rating {
                        HStack(spacing: 2) {
                            ForEach(0..<Int(rating), id: \.self) { _ in
                                Image(systemName: "star.fill")
                                    .font(.caption)
                                    .foregroundStyle(Color.cageGold)
                            }
                        }
                    }

                    if let mood = event.mood {
                        Text(mood)
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)
                    }
                }

                if let location = event.location {
                    Label(location, systemImage: "location.fill")
                        .font(.caption)
                        .foregroundStyle(Color.tertiaryText)
                }

                if !event.companions.isEmpty {
                    Label(event.companions.joined(separator: ", "), systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundStyle(Color.tertiaryText)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(Color.tertiaryText)
        }
        .padding(Spacing.sm)
        .background(Color.glassLight)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
