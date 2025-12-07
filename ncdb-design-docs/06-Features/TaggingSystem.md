# NCDB Tagging System

## Overview

The tagging system allows users to create custom labels for organizing their Nicolas Cage movie collection beyond the built-in categories. Tags provide flexible, personal organization that adapts to each user's preferences.

## Core Concepts

### Tag Philosophy

1. **User-Defined**: Users create their own tags with custom names, colors, and icons
2. **Many-to-Many**: A movie can have multiple tags; a tag can apply to multiple movies
3. **Non-Destructive**: Deleting a tag doesn't affect the movies themselves
4. **Visual**: Tags are designed to be visually distinct and recognizable
5. **Filterable**: Tags can be used to filter movie lists

### Use Cases

- **Mood-Based**: "Comfort Movies", "Late Night", "Feel Good"
- **Context-Based**: "Date Night", "With Friends", "Solo Watch"
- **Quality Markers**: "Hidden Gems", "So Bad It's Good", "Must Rewatch"
- **Personal Categories**: "Favorites of 2024", "Childhood Memories", "To Recommend"

## Data Model

### CustomTag Entity

```swift
@Model
final class CustomTag {
    var id: UUID
    var name: String
    var color: String           // Hex color code
    var icon: String?           // SF Symbol name (optional)
    var createdDate: Date
    var productions: [Production]

    init(name: String, color: String = "#FFD700") {
        self.id = UUID()
        self.name = name
        self.color = color
        self.createdDate = Date()
        self.productions = []
    }
}

// Relationship in Production model
@Model
final class Production {
    // ... other properties
    @Relationship(inverse: \CustomTag.productions)
    var tags: [CustomTag]
}
```

### Tag Constraints

```swift
struct TagConstraints {
    static let maxNameLength = 30
    static let maxTagsPerMovie = 10
    static let maxTotalTags = 50

    static let defaultColors: [String] = [
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

    static let defaultIcons: [String] = [
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
}
```

## User Interface

### Tag Management View

```
┌─────────────────────────────────────┐
│  Tags                        [+]   │
├─────────────────────────────────────┤
│  🔍 Search tags                     │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔴 Comfort Movies      (12) │ ✏️│
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 🟡 Hidden Gems          (8) │ ✏️│
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 🔵 Date Night           (5) │ ✏️│
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 🟣 So Bad It's Good     (3) │ ✏️│
│  └─────────────────────────────┘   │
│                                     │
│            Swipe to delete          │
└─────────────────────────────────────┘
```

### Tag Editor Sheet

```swift
struct TagEditorSheet: View {
    enum Mode {
        case create
        case edit(CustomTag)
    }

    let mode: Mode
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var selectedColor = "#FFD700"
    @State private var selectedIcon: String?

    var body: some View {
        NavigationStack {
            Form {
                // Name input
                Section("Name") {
                    TextField("Tag Name", text: $name)
                        .textInputAutocapitalization(.words)
                }

                // Color picker
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Spacing.md) {
                        ForEach(TagConstraints.defaultColors, id: \.self) { color in
                            ColorCircle(color: color, isSelected: selectedColor == color) {
                                selectedColor = color
                            }
                        }
                    }
                }

                // Icon picker (optional)
                Section("Icon (Optional)") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: Spacing.md) {
                        // No icon option
                        IconCircle(icon: nil, color: selectedColor, isSelected: selectedIcon == nil) {
                            selectedIcon = nil
                        }

                        ForEach(TagConstraints.defaultIcons, id: \.self) { icon in
                            IconCircle(icon: icon, color: selectedColor, isSelected: selectedIcon == icon) {
                                selectedIcon = icon
                            }
                        }
                    }
                }

                // Preview
                Section("Preview") {
                    HStack {
                        Spacer()
                        TagChip(
                            text: name.isEmpty ? "Tag Name" : name,
                            color: Color(hex: selectedColor) ?? .cageGold,
                            icon: selectedIcon
                        )
                        Spacer()
                    }
                }

                // Delete option (edit mode only)
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
            .navigationTitle(mode.isCreate ? "New Tag" : "Edit Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
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
```

## Tag Selection

### From Movie Detail

```swift
struct MovieTagSection: View {
    let movie: Production
    @State private var showTagSelection = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack {
                Text("Tags")
                    .font(Typography.sectionHeader)
                Spacer()
                Button(action: { showTagSelection = true }) {
                    Image(systemName: "plus.circle")
                }
            }

            if movie.tags.isEmpty {
                Text("No tags added")
                    .font(Typography.body)
                    .foregroundStyle(.secondary)
            } else {
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(movie.tags) { tag in
                        TagChip(
                            text: tag.name,
                            color: Color(hex: tag.color) ?? .cageGold,
                            icon: tag.icon
                        )
                        .contextMenu {
                            Button(role: .destructive) {
                                removeTag(tag)
                            } label: {
                                Label("Remove Tag", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showTagSelection) {
            TagSelectionView(selectedTags: Binding(
                get: { movie.tags },
                set: { movie.tags = $0 }
            ))
        }
    }

    private func removeTag(_ tag: CustomTag) {
        movie.tags.removeAll { $0.id == tag.id }
        try? modelContext.save()
    }
}
```

### Tag Selection Sheet

```swift
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
                                // Color indicator with optional icon
                                Circle()
                                    .fill(Color(hex: tag.color) ?? .cageGold)
                                    .frame(width: 24, height: 24)
                                    .overlay {
                                        if let icon = tag.icon {
                                            Image(systemName: icon)
                                                .font(.caption2)
                                                .foregroundStyle(.white)
                                        }
                                    }

                                Text(tag.name)
                                    .font(Typography.body)

                                Spacer()

                                // Checkmark for selected
                                if selectedTags.contains(where: { $0.id == tag.id }) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.cageGold)
                                }
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                }

                // Create new tag option
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
            guard selectedTags.count < TagConstraints.maxTagsPerMovie else {
                // Show limit warning
                return
            }
            selectedTags.append(tag)
        }
    }
}
```

## Tag Filtering

### Filter Pills

Horizontal scrollable tag chips for quick filtering:

```swift
struct TagFilterPills: View {
    let tags: [CustomTag]
    @Binding var selectedTags: Set<String>

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.xs) {
                // "All" option
                FilterChip(
                    text: "All",
                    isSelected: selectedTags.isEmpty
                ) {
                    selectedTags.removeAll()
                }

                ForEach(tags) { tag in
                    FilterChip(
                        text: tag.name,
                        color: Color(hex: tag.color) ?? .cageGold,
                        icon: tag.icon,
                        isSelected: selectedTags.contains(tag.name)
                    ) {
                        toggleFilter(tag.name)
                    }
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }

    private func toggleFilter(_ tagName: String) {
        if selectedTags.contains(tagName) {
            selectedTags.remove(tagName)
        } else {
            selectedTags.insert(tagName)
        }
    }
}
```

### Applying Filters

```swift
// In MovieListViewModel
var filteredMovies: [Production] {
    var result = allMovies

    // Apply tag filter
    if !selectedTagNames.isEmpty {
        result = result.filter { movie in
            let movieTagNames = Set(movie.tags.map { $0.name })
            return !movieTagNames.isDisjoint(with: selectedTagNames)
        }
    }

    return result
}
```

## Tag Components

### Tag Chip

```swift
struct TagChip: View {
    let text: String
    var color: Color = .cageGold
    var icon: String?
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: Spacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(text)
                .font(Typography.caption1Bold)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(
            Capsule()
                .fill(isSelected ? color : color.opacity(0.7))
        )
        .overlay(
            Capsule()
                .stroke(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}
```

### Color Circle

```swift
struct ColorCircle: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: color) ?? .gray)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(Color.primary, lineWidth: isSelected ? 3 : 0)
                )
        }
        .buttonStyle(.plain)
    }
}
```

### Icon Circle

```swift
struct IconCircle: View {
    let icon: String?
    let color: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(icon == nil ? Color.secondaryBackground : Color(hex: color) ?? .gray)
                .frame(width: 44, height: 44)
                .overlay {
                    if let icon {
                        Image(systemName: icon)
                            .foregroundStyle(.white)
                    } else {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    }
                }
                .overlay(
                    Circle()
                        .stroke(Color.primary, lineWidth: isSelected ? 3 : 0)
                )
        }
        .buttonStyle(.plain)
    }
}
```

## Flow Layout

For wrapping tags that don't fit on one line:

```swift
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(
                x: bounds.minX + result.positions[index].x,
                y: bounds.minY + result.positions[index].y
            ), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > width && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: width, height: y + lineHeight)
        }
    }
}
```

## Batch Operations

### Add Tag to Multiple Movies

```swift
struct BatchTagSheet: View {
    let movies: [Production]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CustomTag.name) private var allTags: [CustomTag]

    @State private var selectedTag: CustomTag?

    var body: some View {
        NavigationStack {
            List(allTags) { tag in
                Button(action: { selectedTag = tag }) {
                    HStack {
                        TagChip(text: tag.name, color: Color(hex: tag.color) ?? .cageGold, icon: tag.icon)
                        Spacer()
                        if selectedTag?.id == tag.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.cageGold)
                        }
                    }
                }
            }
            .navigationTitle("Add Tag to \(movies.count) Movies")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") { applyTag() }
                        .disabled(selectedTag == nil)
                }
            }
        }
    }

    private func applyTag() {
        guard let tag = selectedTag else { return }

        for movie in movies {
            if !movie.tags.contains(where: { $0.id == tag.id }) {
                movie.tags.append(tag)
            }
        }

        try? modelContext.save()
        dismiss()
    }
}
```

### Remove Tag from All Movies

```swift
func removeTagFromAllMovies(_ tag: CustomTag) {
    for movie in tag.productions {
        movie.tags.removeAll { $0.id == tag.id }
    }
    try? modelContext.save()
}
```

## Tag Statistics

```swift
struct TagStats: View {
    @Query private var tags: [CustomTag]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Tag Statistics")
                .font(Typography.sectionHeader)

            ForEach(sortedTags) { tag in
                HStack {
                    TagChip(text: tag.name, color: Color(hex: tag.color) ?? .cageGold, icon: tag.icon)

                    Spacer()

                    Text("\(tag.productions.count) movies")
                        .font(Typography.caption1)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var sortedTags: [CustomTag] {
        tags.sorted { $0.productions.count > $1.productions.count }
    }
}
```

## Search Integration

Tags appear in search suggestions and results:

```swift
// In SearchViewModel
var suggestions: [String] {
    var allSuggestions: [String] = []

    // ... other suggestions

    // Tag matches
    let tagSuggestions = allTags
        .filter { $0.name.lowercased().contains(query.lowercased()) }
        .prefix(3)
        .map { "tag:\($0.name)" }
    allSuggestions.append(contentsOf: tagSuggestions)

    return allSuggestions
}

// Handle tag search
func handleTagSearch(_ tagName: String) {
    selectedTagFilter = tagName
    // Filter movies by tag
}
```

## Import/Export

### Export Tags

```swift
func exportTags() -> Data? {
    struct TagExport: Codable {
        let name: String
        let color: String
        let icon: String?
    }

    let exports = tags.map { TagExport(name: $0.name, color: $0.color, icon: $0.icon) }
    return try? JSONEncoder().encode(exports)
}
```

### Import Tags

```swift
func importTags(from data: Data) {
    struct TagExport: Codable {
        let name: String
        let color: String
        let icon: String?
    }

    guard let imports = try? JSONDecoder().decode([TagExport].self, from: data) else { return }

    for tagData in imports {
        // Check if tag already exists
        if !tags.contains(where: { $0.name.lowercased() == tagData.name.lowercased() }) {
            let newTag = CustomTag(name: tagData.name, color: tagData.color)
            newTag.icon = tagData.icon
            modelContext.insert(newTag)
        }
    }

    try? modelContext.save()
}
```

## Accessibility

```swift
TagChip(text: tag.name, color: tagColor, icon: tag.icon)
    .accessibilityLabel("\(tag.name) tag")
    .accessibilityHint("Double tap to filter by this tag")
    .accessibilityAddTraits(.isButton)
```

## Edge Cases

### Tag Name Validation

```swift
func validateTagName(_ name: String) -> TagNameValidation {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)

    if trimmed.isEmpty {
        return .invalid("Tag name cannot be empty")
    }

    if trimmed.count > TagConstraints.maxNameLength {
        return .invalid("Tag name too long (max \(TagConstraints.maxNameLength) characters)")
    }

    if existingTags.contains(where: { $0.name.lowercased() == trimmed.lowercased() }) {
        return .invalid("A tag with this name already exists")
    }

    return .valid
}

enum TagNameValidation {
    case valid
    case invalid(String)
}
```

### Deleting Tags with Movies

Show confirmation when deleting a tag that has movies:

```swift
.confirmationDialog(
    "Delete Tag?",
    isPresented: $showDeleteConfirmation,
    titleVisibility: .visible
) {
    Button("Delete Tag", role: .destructive) {
        deleteTag(tagToDelete)
    }
} message: {
    Text("This tag is used by \(tagToDelete.productions.count) movies. Deleting it will remove it from all movies.")
}
```

## Future Enhancements

1. **Smart Tags**: Auto-generated tags based on genres, decades, ratings
2. **Nested Tags**: Parent/child tag relationships
3. **Tag Templates**: Pre-made tag sets for quick setup
4. **Collaborative Tags**: Shared tags between users
5. **Tag Insights**: Analytics about tag usage patterns
6. **Quick Tag Gestures**: Swipe to quickly add common tags
