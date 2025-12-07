// NCDB Custom Tags View
// Tag management and organization interface

import SwiftUI
import SwiftData

// MARK: - Custom Tags View

/// Main view for managing custom tags
///
/// Features:
/// - List of all custom tags
/// - Create new tags
/// - Edit existing tags (name, color, icon)
/// - Delete tags
/// - View movies with each tag
struct CustomTagsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CustomTag.name) private var tags: [CustomTag]

    @State private var showCreateSheet = false
    @State private var tagToEdit: CustomTag?
    @State private var searchText = ""

    var filteredTags: [CustomTag] {
        if searchText.isEmpty {
            return tags
        }
        return tags.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if tags.isEmpty {
                    EmptyStateView(
                        icon: "tag.fill",
                        title: "No Tags Yet",
                        message: "Create custom tags to organize your movies.",
                        actionTitle: "Create Tag"
                    ) {
                        showCreateSheet = true
                    }
                } else {
                    List {
                        ForEach(filteredTags) { tag in
                            TagRow(tag: tag) {
                                tagToEdit = tag
                            }
                        }
                        .onDelete(perform: deleteTags)
                    }
                    .searchable(text: $searchText, prompt: "Search tags")
                }
            }
            .navigationTitle("Tags")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showCreateSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                TagEditorSheet(mode: .create)
            }
            .sheet(item: $tagToEdit) { tag in
                TagEditorSheet(mode: .edit(tag))
            }
        }
    }

    private func deleteTags(at offsets: IndexSet) {
        for index in offsets {
            let tag = filteredTags[index]
            modelContext.delete(tag)
        }
        try? modelContext.save()
    }
}

// MARK: - Tag Row

struct TagRow: View {
    let tag: CustomTag
    let onEdit: () -> Void

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Color indicator
            Circle()
                .fill(Color(hex: tag.color) ?? .cageGold)
                .frame(width: 24, height: 24)
                .overlay(
                    Group {
                        if let icon = tag.icon {
                            Image(systemName: icon)
                                .font(.caption2)
                                .foregroundStyle(.white)
                        }
                    }
                )

            // Tag info
            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(tag.name)
                    .font(Typography.body)

                Text("\(tag.productions.count) movies")
                    .font(Typography.caption1)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Edit button
            Button(action: onEdit) {
                Image(systemName: "pencil")
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}

// MARK: - Tag Editor Sheet

struct TagEditorSheet: View {
    enum Mode: Identifiable {
        case create
        case edit(CustomTag)

        var id: String {
            switch self {
            case .create: return "create"
            case .edit(let tag): return tag.id.uuidString
            }
        }
    }

    let mode: Mode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedColor = "#FFD700"
    @State private var selectedIcon: String?

    let colors: [String] = [
        "#FFD700", // Gold
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Yellow
        "#34C759", // Green
        "#00C7BE", // Teal
        "#007AFF", // Blue
        "#5856D6", // Indigo
        "#AF52DE", // Purple
        "#FF2D55", // Pink
    ]

    let icons: [String] = [
        "star.fill",
        "heart.fill",
        "flame.fill",
        "bolt.fill",
        "crown.fill",
        "medal.fill",
        "flag.fill",
        "bookmark.fill",
        "tag.fill",
        "folder.fill"
    ]

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var title: String {
        switch mode {
        case .create: return "New Tag"
        case .edit: return "Edit Tag"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                // Name
                Section("Name") {
                    TextField("Tag Name", text: $name)
                }

                // Color
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Spacing.md) {
                        ForEach(colors, id: \.self) { color in
                            Button(action: { selectedColor = color }) {
                                Circle()
                                    .fill(Color(hex: color) ?? .gray)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                }

                // Icon
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Spacing.md) {
                        // No icon option
                        Button(action: { selectedIcon = nil }) {
                            Circle()
                                .fill(Color.secondaryBackground)
                                .frame(width: 44, height: 44)
                                .overlay(
                                    Image(systemName: "xmark")
                                        .foregroundStyle(.secondary)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedIcon == nil ? 3 : 0)
                                )
                        }
                        .buttonStyle(.plain)

                        ForEach(icons, id: \.self) { icon in
                            Button(action: { selectedIcon = icon }) {
                                Circle()
                                    .fill(Color(hex: selectedColor) ?? .cageGold)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: icon)
                                            .foregroundStyle(.white)
                                    )
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedIcon == icon ? 3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, Spacing.sm)
                } header: {
                    Text("Icon (Optional)")
                }

                // Preview
                Section("Preview") {
                    HStack {
                        Spacer()
                        TagPreview(name: name.isEmpty ? "Tag Name" : name, color: selectedColor, icon: selectedIcon)
                        Spacer()
                    }
                    .padding(.vertical, Spacing.sm)
                }

                // Delete (edit mode only)
                if case .edit(let tag) = mode {
                    Section {
                        Button(role: .destructive) {
                            deleteTag(tag)
                        } label: {
                            HStack {
                                Spacer()
                                Text("Delete Tag")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .onAppear {
                if case .edit(let tag) = mode {
                    name = tag.name
                    selectedColor = tag.color
                    selectedIcon = tag.icon
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        switch mode {
        case .create:
            let newTag = CustomTag(name: trimmedName, color: selectedColor)
            newTag.icon = selectedIcon
            modelContext.insert(newTag)

        case .edit(let tag):
            tag.name = trimmedName
            tag.color = selectedColor
            tag.icon = selectedIcon
        }

        try? modelContext.save()
        dismiss()
    }

    private func deleteTag(_ tag: CustomTag) {
        modelContext.delete(tag)
        try? modelContext.save()
        dismiss()
    }
}

// MARK: - Tag Preview

struct TagPreview: View {
    let name: String
    let color: String
    let icon: String?

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(name)
                .font(Typography.caption1Bold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(Color(hex: color) ?? .cageGold)
        )
    }
}

// MARK: - Tag Selection View

/// View for selecting tags to apply to a movie
struct TagSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomTag.name) private var allTags: [CustomTag]

    @Binding var selectedTags: [CustomTag]
    @State private var showCreateSheet = false

    var body: some View {
        NavigationStack {
            List {
                if allTags.isEmpty {
                    Section {
                        Text("No tags created yet.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(allTags) { tag in
                        Button(action: { toggleTag(tag) }) {
                            HStack {
                                Circle()
                                    .fill(Color(hex: tag.color) ?? .cageGold)
                                    .frame(width: 20, height: 20)
                                    .overlay(
                                        Group {
                                            if let icon = tag.icon {
                                                Image(systemName: icon)
                                                    .font(.system(size: 10))
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                    )

                                Text(tag.name)

                                Spacer()

                                if selectedTags.contains(where: { $0.id == tag.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.cageGold)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                Section {
                    Button(action: { showCreateSheet = true }) {
                        Label("Create New Tag", systemImage: "plus.circle")
                    }
                }
            }
            .navigationTitle("Select Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                TagEditorSheet(mode: .create)
            }
        }
    }

    private func toggleTag(_ tag: CustomTag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }
}

// MARK: - Tag Filter Pills

/// Horizontal scrolling tag filter for movie list
struct TagFilterPills: View {
    let tags: [CustomTag]
    @Binding var selectedTags: Set<String>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // All button
                TagChip(
                    text: "All",
                    isSelected: selectedTags.isEmpty
                ) {
                    selectedTags.removeAll()
                }

                ForEach(tags) { tag in
                    TagChip(
                        text: tag.name,
                        color: Color(hex: tag.color) ?? .cageGold,
                        icon: tag.icon,
                        isSelected: selectedTags.contains(tag.name)
                    ) {
                        if selectedTags.contains(tag.name) {
                            selectedTags.remove(tag.name)
                        } else {
                            selectedTags.insert(tag.name)
                        }
                    }
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }
}

// MARK: - Preview

#Preview("Tags View") {
    CustomTagsView()
        .modelContainer(for: CustomTag.self, inMemory: true)
}

#Preview("Tag Editor") {
    TagEditorSheet(mode: .create)
        .modelContainer(for: CustomTag.self, inMemory: true)
}
