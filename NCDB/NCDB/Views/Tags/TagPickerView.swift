//
//  TagPickerView.swift
//  NCDB
//

import SwiftUI
import SwiftData

/// Assign tags to a production, and create new ones.
///
/// `CustomTag` shipped as a fully-formed model — many-to-many relationship,
/// colour, icon — with no interface anywhere in the app. This is that interface.
struct TagPickerView: View {

    let production: Production

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CustomTag.name) private var allTags: [CustomTag]

    @State private var newTagName = ""
    @State private var newTagColor = Color.cageGold
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            List {
                if allTags.isEmpty && !isCreating {
                    Section {
                        ContentUnavailableView {
                            Label("No Tags Yet", systemImage: "tag")
                        } description: {
                            Text("Tags are your own labels — “Comfort Movies”, “So Bad It's Good”, “Date Night”.")
                        }
                    }
                }

                if !allTags.isEmpty {
                    Section("Tags") {
                        ForEach(allTags) { tag in
                            tagRow(tag)
                        }
                        .onDelete(perform: deleteTags)
                    }
                }

                Section {
                    if isCreating {
                        newTagFields
                    } else {
                        Button {
                            withAnimation { isCreating = true }
                        } label: {
                            Label("New Tag", systemImage: "plus.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle("Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    // MARK: - Rows

    private func tagRow(_ tag: CustomTag) -> some View {
        Button {
            toggle(tag)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: tag.icon ?? "tag.fill")
                    .foregroundStyle(tag.color)
                    .frame(width: 24)

                Text(tag.name)
                    .foregroundStyle(Color.primaryText)

                Spacer()

                Text("\(tag.productionCount)")
                    .font(.caption)
                    .foregroundStyle(Color.tertiaryText)

                if isApplied(tag) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.cageGold)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }

    private var newTagFields: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            TextField("Tag name", text: $newTagName)
                .textInputAutocapitalization(.words)

            ColorPicker("Colour", selection: $newTagColor, supportsOpacity: false)

            HStack {
                Button("Cancel") {
                    withAnimation {
                        isCreating = false
                        newTagName = ""
                    }
                }
                .foregroundStyle(Color.secondaryText)

                Spacer()

                Button("Create") { createTag() }
                    .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    // MARK: - Actions

    private func isApplied(_ tag: CustomTag) -> Bool {
        production.appliedTags.contains { $0.id == tag.id }
    }

    private func toggle(_ tag: CustomTag) {
        if isApplied(tag) {
            production.removeTag(tag)
        } else {
            production.addTag(tag)
        }

        save()
        HapticManager.shared.selectionChanged()
    }

    private func createTag() {
        let name = newTagName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }

        let tag = CustomTag(name: name, colorHex: newTagColor.toHex() ?? "#FFD700")
        modelContext.insert(tag)
        production.addTag(tag)

        save()
        HapticManager.shared.success()

        withAnimation {
            newTagName = ""
            newTagColor = .cageGold
            isCreating = false
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(allTags[index])
        }
        save()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            Logger.shared.error("Failed to save tags: \(error)", category: .database)
        }
    }
}

// MARK: - Tag Chips

/// Horizontal row of a production's tags.
///
/// Grouped in a `GlassEffectContainer` with a shared union id, so adjacent
/// chips fuse into a single glass shape instead of reading as separate pills —
/// and adding or removing a tag morphs the shape rather than popping.
struct TagChipRow: View {
    let tags: [CustomTag]

    @Namespace private var tagSpace

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            GlassEffectContainer(spacing: 12) {
                HStack(spacing: Spacing.xs) {
                    ForEach(tags) { tag in
                        TagChip(
                            text: tag.name,
                            color: tag.color,
                            icon: tag.icon ?? "tag.fill"
                        )
                        .glassEffect(.regular.tint(tag.color.opacity(0.5)), in: .capsule)
                        .glassEffectUnion(id: "tags", namespace: tagSpace)
                        .glassEffectID(tag.id, in: tagSpace)
                    }
                }
            }
            .animation(.spring(duration: 0.35), value: tags.map(\.id))
        }
    }
}

#Preview {
    TagPickerView(production: Production(title: "Face/Off", releaseYear: 1997))
        .modelContainer(for: [Production.self, CustomTag.self], inMemory: true)
}
