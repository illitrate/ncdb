// Liquid Glass Design System Components
// Reusable SwiftUI views with frosted glass aesthetic

import SwiftUI

// MARK: - Glass Card

/// A frosted panel built on the system Liquid Glass effect.
///
/// Before 2.0 this was `.ultraThinMaterial` plus a hand-drawn white gradient
/// stroke — the pre-iOS 26 way of approximating glass. It now uses the real
/// thing, so it picks up the system's lensing, highlights and motion response.
struct GlassCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 20
    var padding: CGFloat = 20

    init(
        cornerRadius: CGFloat = 20,
        padding: CGFloat = 20,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
    }
}

// MARK: - Glass Button

/// A button on the system glass button styles.
///
/// The `style` cases map onto the native styles rather than onto hand-rolled
/// materials and shadows: primary is prominent glass tinted Cage Gold,
/// secondary is plain glass, destructive is glass carrying the destructive role.
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var style: GlassButtonStyle = .primary

    init(title: String, icon: String? = nil, style: GlassButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.style = style
        self.action = action
    }

    var body: some View {
        switch style {
        case .primary:
            button
                .buttonStyle(.glassProminent)
                .tint(.cageGold)
                // Prominent glass fills with the tint, so the label needs to be
                // dark against Cage Gold — matching GoldBadge.
                .foregroundStyle(.black)
        case .secondary:
            button
                .buttonStyle(.glass)
                .tint(.white)
        case .destructive:
            Button(role: .destructive, action: action) { label }
                .buttonStyle(.glass)
                .tint(.red)
        }
    }

    private var button: some View {
        Button(action: action) { label }
    }

    private var label: some View {
        HStack(spacing: 8) {
            if let icon {
                Image(systemName: icon)
                    .font(.headline)
            }
            Text(title)
                .font(.headline)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

enum GlassButtonStyle {
    case primary
    case secondary
    case destructive
}

// MARK: - Glass Frame (for posters/images)
struct GlassFrame<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 16

    init(
        cornerRadius: CGFloat = 16,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .padding(8)
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius + 4))
            .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
    }
}

// MARK: - Gold Badge
struct GoldBadge: View {
    let text: String
    let icon: String?

    init(_ text: String, icon: String? = nil) {
        self.text = text
        self.icon = icon
    }

    var body: some View {
        HStack(spacing: 6) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption.bold())
            }
            Text(text)
                .font(.caption.bold())
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cageGold,
                            Color.cageGold.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color.cageGold.opacity(0.6), radius: 8, x: 0, y: 4)
        )
    }
}

// MARK: - Glass Text Field
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    var icon: String?
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .foregroundStyle(Color.secondaryText)
            }

            if isSecure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
            }
        }
        .padding(Spacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: Sizes.cornerRadiusMedium))
    }
}

// MARK: - Previews

#Preview("Glass Components") {
    ZStack {
        Color.primaryBackground.ignoresSafeArea()

        VStack(spacing: 24) {
            GlassCard {
                VStack(alignment: .leading) {
                    Text("Glass Card")
                        .font(.headline)
                    Text("A frosted glass container")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            GlassEffectContainer(spacing: 16) {
                HStack(spacing: 16) {
                    GlassButton(title: "Primary", icon: "star.fill") {}
                    GlassButton(title: "Secondary", style: .secondary) {}
                }
            }

            GoldBadge("Cage Gold", icon: "star.fill")

            GlassFrame {
                Rectangle()
                    .fill(Color.cageGold.opacity(0.5))
                    .frame(width: 100, height: 150)
            }
        }
        .padding()
    }
}
