// Liquid Glass Design System Components
// Reusable SwiftUI views with frosted glass aesthetic

import SwiftUI

// MARK: - Glass Card
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
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.2),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

// MARK: - Glass Button
struct GlassButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var style: GlassButtonStyle = .primary
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.headline)
                }
                Text(title)
                    .font(.headline)
            }
            .foregroundStyle(style.foregroundColor)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(style.backgroundColor)
                    .shadow(color: style.shadowColor, radius: 8, x: 0, y: 4)
            )
        }
    }
}

enum GlassButtonStyle {
    case primary
    case secondary
    case destructive
    
    var backgroundColor: Material {
        switch self {
        case .primary: return .thickMaterial
        case .secondary: return .thinMaterial
        case .destructive: return .ultraThinMaterial
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary: return Color("CageGold")
        case .secondary: return .white
        case .destructive: return .red
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .primary: return Color("CageGold").opacity(0.5)
        case .secondary: return .black.opacity(0.3)
        case .destructive: return .red.opacity(0.4)
        }
    }
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
            .background(
                RoundedRectangle(cornerRadius: cornerRadius + 4)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 10)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius + 4)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
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
                            Color("CageGold"),
                            Color("CageGold").opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: Color("CageGold").opacity(0.6), radius: 8, x: 0, y: 4)
        )
    }
}
