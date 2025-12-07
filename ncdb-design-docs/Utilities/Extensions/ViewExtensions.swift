// NCDB View Extensions
// SwiftUI view modifiers and extensions

import SwiftUI

// MARK: - Conditional Modifiers

extension View {

    /// Apply a modifier conditionally
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    /// Apply a modifier if value is non-nil
    @ViewBuilder
    func ifLet<Value, Content: View>(_ value: Value?, transform: (Self, Value) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }

    /// Apply different modifiers based on condition
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        then trueTransform: (Self) -> TrueContent,
        else falseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueTransform(self)
        } else {
            falseTransform(self)
        }
    }
}

// MARK: - Frame Modifiers

extension View {

    /// Expand to fill available space
    func expandWidth() -> some View {
        frame(maxWidth: .infinity)
    }

    /// Expand to fill available height
    func expandHeight() -> some View {
        frame(maxHeight: .infinity)
    }

    /// Expand to fill all available space
    func expand() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Center in available space
    func centered() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Square frame with given size
    func square(_ size: CGFloat) -> some View {
        frame(width: size, height: size)
    }
}

// MARK: - Card Style

extension View {

    /// Apply standard card styling
    func cardStyle(
        cornerRadius: CGFloat = 16,
        shadowRadius: CGFloat = 8,
        shadowOpacity: Double = 0.1
    ) -> some View {
        self
            .background(Color.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(shadowOpacity),
                radius: shadowRadius,
                x: 0,
                y: 4
            )
    }

    /// Apply glass morphism effect
    func glassStyle(cornerRadius: CGFloat = 16) -> some View {
        self
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

// MARK: - Navigation

extension View {

    /// Hide navigation bar
    func hideNavigationBar() -> some View {
        self
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
    }

    /// Custom navigation bar title with inline display
    func inlineNavigationTitle(_ title: String) -> some View {
        self
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Interaction

extension View {

    /// Make view tappable with full area
    func tappableArea() -> some View {
        contentShape(Rectangle())
    }

    /// Add tap gesture with haptic feedback
    func onTapWithHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.impactOccurred()
            action()
        }
    }

    /// Add long press gesture
    func onLongPress(minimumDuration: Double = 0.5, action: @escaping () -> Void) -> some View {
        self.onLongPressGesture(minimumDuration: minimumDuration) {
            action()
        }
    }
}

// MARK: - Animation

extension View {

    /// Apply spring animation
    func springAnimation() -> some View {
        animation(.spring(response: 0.35, dampingFraction: 0.7), value: UUID())
    }

    /// Animate on appear
    func animateOnAppear<Value: Equatable>(value: Binding<Value>, to newValue: Value, delay: Double = 0) -> some View {
        self.onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(delay)) {
                value.wrappedValue = newValue
            }
        }
    }

    /// Shimmer loading effect
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.5),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                    }
                    .mask(content)
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Visibility

extension View {

    /// Hide view without removing from layout
    func hidden(_ isHidden: Bool) -> some View {
        opacity(isHidden ? 0 : 1)
    }

    /// Remove view from hierarchy conditionally
    @ViewBuilder
    func visible(_ isVisible: Bool) -> some View {
        if isVisible {
            self
        }
    }
}

// MARK: - Loading States

extension View {

    /// Overlay with loading indicator
    func loading(_ isLoading: Bool) -> some View {
        self.overlay {
            if isLoading {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.cageGold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }

    /// Redacted as placeholder
    func loadingPlaceholder(_ isLoading: Bool) -> some View {
        self.redacted(reason: isLoading ? .placeholder : [])
    }
}

// MARK: - Safe Area

extension View {

    /// Read safe area insets
    func readSafeAreaInsets(_ insets: Binding<EdgeInsets>) -> some View {
        self.background(
            GeometryReader { geometry in
                Color.clear
                    .preference(key: SafeAreaInsetsKey.self, value: geometry.safeAreaInsets)
            }
        )
        .onPreferenceChange(SafeAreaInsetsKey.self) { value in
            insets.wrappedValue = value
        }
    }
}

struct SafeAreaInsetsKey: PreferenceKey {
    static var defaultValue: EdgeInsets = .init()

    static func reduce(value: inout EdgeInsets, nextValue: () -> EdgeInsets) {
        value = nextValue()
    }
}

// MARK: - Keyboard

extension View {

    /// Hide keyboard on tap
    func hideKeyboardOnTap() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - Debug

extension View {

    /// Debug border
    func debugBorder(_ color: Color = .red, width: CGFloat = 1) -> some View {
        #if DEBUG
        self.border(color, width: width)
        #else
        self
        #endif
    }

    /// Print on appear (debug only)
    func debugOnAppear(_ message: String) -> some View {
        #if DEBUG
        self.onAppear { print("DEBUG: \(message)") }
        #else
        self
        #endif
    }
}

// MARK: - Accessibility

extension View {

    /// Combine accessibility label and hint
    func accessibilityInfo(label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .if(hint != nil) { view in
                view.accessibilityHint(hint!)
            }
    }

    /// Make element a button for accessibility
    func accessibilityButton() -> some View {
        self.accessibilityAddTraits(.isButton)
    }

    /// Hide from accessibility
    func accessibilityHide() -> some View {
        self.accessibilityHidden(true)
    }
}

// MARK: - Color Extensions

extension Color {

    /// Initialize from hex string
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }

        let length = hexSanitized.count
        let r, g, b, a: Double

        switch length {
        case 6: // RGB (no alpha)
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        case 8: // RGBA
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        default:
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    /// App-specific colors
//    static let cageGold = Color(hex: "#FFD700") ?? .yellow
    static let primaryBackground = Color(.systemBackground)
    static let secondaryBackground = Color(.secondarySystemBackground)
    static let cardBackground = Color(.tertiarySystemBackground)
}

// MARK: - Preview Helpers

extension View {

    /// Preview with common device sizes
    func previewDevices() -> some View {
        Group {
            self.previewDevice("iPhone 15 Pro")
            self.previewDevice("iPhone SE (3rd generation)")
            self.previewDevice("iPad Pro (11-inch) (4th generation)")
        }
    }

    /// Preview in dark mode
    func previewDarkMode() -> some View {
        self.preferredColorScheme(.dark)
    }

    /// Preview in light and dark mode
    func previewBothModes() -> some View {
        Group {
            self.preferredColorScheme(.light)
                .previewDisplayName("Light")
            self.preferredColorScheme(.dark)
                .previewDisplayName("Dark")
        }
    }
}
