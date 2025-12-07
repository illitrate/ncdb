//
//  WatchEventLogger.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Detailed watch event logging form
struct WatchEventLogger: View {
    let production: Production
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var watchDate = Date()
    @State private var location: String = ""
    @State private var companions: String = ""
    @State private var mood: String = ""
    @State private var notes: String = ""
    @State private var rating: Double = 0

    var body: some View {
        NavigationStack {
            Form {
                // Movie info
                Section {
                    HStack {
                        Text("Movie")
                            .foregroundStyle(Color.secondaryText)
                        Spacer()
                        Text(production.title)
                            .foregroundStyle(Color.primaryText)
                    }
                }

                // Watch details
                Section("When") {
                    DatePicker("Date & Time", selection: $watchDate)
                }

                Section("Where") {
                    TextField("Location (optional)", text: $location)
                }

                Section("With Whom") {
                    TextField("Companions (optional)", text: $companions, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Mood") {
                    Picker("How were you feeling?", selection: $mood) {
                        Text("Not specified").tag("")
                        Text("😊 Happy").tag("Happy")
                        Text("😢 Sad").tag("Sad")
                        Text("😴 Tired").tag("Tired")
                        Text("🎉 Excited").tag("Excited")
                        Text("😌 Relaxed").tag("Relaxed")
                        Text("🤔 Thoughtful").tag("Thoughtful")
                    }
                }

                // Rating
                Section("Rating") {
                    StarRatingView(
                        rating: rating,
                        isInteractive: true,
                        onRatingChanged: { newRating in
                            rating = newRating
                        }
                    )
                }

                // Notes
                Section("Notes") {
                    TextField("Your thoughts (optional)", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
                }
            }
            .navigationTitle("Log Watch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWatchEvent()
                    }
                }
            }
        }
    }

    private func saveWatchEvent() {
        let companionsList = companions
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        WatchHistoryManager.shared.createWatchEvent(
            for: production,
            date: watchDate,
            location: location.isEmpty ? nil : location,
            companions: companionsList,
            mood: mood.isEmpty ? nil : mood,
            notes: notes.isEmpty ? nil : notes,
            rating: rating > 0 ? rating : nil
        )

        onComplete()
        dismiss()
    }
}
