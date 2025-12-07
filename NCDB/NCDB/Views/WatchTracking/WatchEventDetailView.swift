//
//  WatchEventDetailView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Full detail sheet for a watch event
struct WatchEventDetailView: View {
    let event: WatchEvent
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Movie title
                    if let production = event.production {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Movie")
                                .font(.caption)
                                .foregroundStyle(Color.tertiaryText)

                            Text(production.title)
                                .font(.title2.bold())
                                .foregroundStyle(Color.primaryText)
                        }
                    }

                    Divider()

                    // Date & Time
                    DetailRow(
                        icon: "calendar",
                        label: "Date",
                        value: event.watchedAt.formatted(date: .long, time: .omitted)
                    )

                    DetailRow(
                        icon: "clock",
                        label: "Time",
                        value: event.watchedAt.formatted(date: .omitted, time: .shortened)
                    )

                    // Location
                    if let location = event.location {
                        Divider()
                        DetailRow(
                            icon: "location.fill",
                            label: "Location",
                            value: location
                        )
                    }

                    // Companions
                    if !event.companions.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Label("Companions", systemImage: "person.2.fill")
                                .font(.caption)
                                .foregroundStyle(Color.tertiaryText)

                            ForEach(event.companions, id: \.self) { companion in
                                Text(companion)
                                    .font(.body)
                                    .foregroundStyle(Color.primaryText)
                            }
                        }
                    }

                    // Mood
                    if let mood = event.mood {
                        Divider()
                        DetailRow(
                            icon: "face.smiling",
                            label: "Mood",
                            value: mood
                        )
                    }

                    // Rating
                    if let rating = event.rating {
                        Divider()
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Label("Rating", systemImage: "star.fill")
                                .font(.caption)
                                .foregroundStyle(Color.tertiaryText)

                            HStack(spacing: 2) {
                                ForEach(0..<Int(rating), id: \.self) { _ in
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(Color.cageGold)
                                }
                                ForEach(Int(rating)..<5, id: \.self) { _ in
                                    Image(systemName: "star")
                                        .foregroundStyle(Color.cageGold.opacity(0.3))
                                }
                            }
                        }
                    }

                    // Notes
                    if let notes = event.notes, !notes.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Label("Notes", systemImage: "note.text")
                                .font(.caption)
                                .foregroundStyle(Color.tertiaryText)

                            Text(notes)
                                .font(.body)
                                .foregroundStyle(Color.primaryText)
                        }
                    }
                }
                .padding(Spacing.lg)
            }
            .background(Color.primaryBackground)
            .navigationTitle("Watch Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
            .confirmationDialog(
                "Delete Watch Event",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    deleteEvent()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this watch event? This cannot be undone.")
            }
        }
    }

    private func deleteEvent() {
        WatchHistoryManager.shared.deleteWatchEvent(event)
        onDelete()
        dismiss()
    }
}

struct DetailRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundStyle(Color.tertiaryText)

            Text(value)
                .font(.body)
                .foregroundStyle(Color.primaryText)
        }
    }
}
