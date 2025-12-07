# NCDB Animation Guidelines

## Overview

Animation in NCDB serves to reinforce the Liquid Glass aesthetic, provide feedback, and guide user attention. iOS 26's Liquid Glass introduces fluid, physics-based animations that we extend throughout the app.

---

## Core Principles

### 1. Purpose Over Polish
Every animation must serve a purpose:
- **Feedback** - Confirm user actions
- **Orientation** - Show spatial relationships
- **Continuity** - Maintain context during transitions
- **Delight** - Reward meaningful interactions (sparingly)

### 2. Respect User Preferences
Always honor system accessibility settings:
```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.8)
}
```

### 3. Performance First
- Target 60fps minimum, 120fps on ProMotion displays
- Offload complex animations to GPU with `drawingGroup()`
- Avoid animating during data loading
- Use `Animation.interactiveSpring()` for gesture-driven animations

---

## Animation Timing

### Duration Reference

| Category | Duration | Use Case |
|----------|----------|----------|
| Instant | 0.1s | Button press feedback, toggles |
| Quick | 0.2s | Small UI changes, hover states |
| Standard | 0.35s | Default transitions, reveals |
| Emphasis | 0.5s | Important state changes, celebrations |
| Slow | 0.8s | Major transitions, onboarding |

### Spring Parameters

```swift
// Standard spring - default for most animations
Animation.spring(response: 0.6, dampingFraction: 0.8)

// Quick spring - snappy feedback
Animation.spring(response: 0.4, dampingFraction: 0.85)

// Bouncy spring - playful emphasis
Animation.spring(response: 0.5, dampingFraction: 0.6)

// Gentle spring - smooth, elegant transitions
Animation.spring(response: 0.8, dampingFraction: 0.9)

// Interactive spring - follows gestures naturally
Animation.interactiveSpring(response: 0.3, dampingFraction: 0.7)
```

---

## Animation Patterns

### Card Appearance

Cards should appear with a subtle scale and fade:

```swift
struct CardAppearAnimation: ViewModifier {
    @State private var isVisible = false

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.95)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isVisible = true
                }
            }
    }
}

// Usage
GlassCard { ... }
    .modifier(CardAppearAnimation())
```

### Staggered List Animation

List items appear in sequence:

```swift
ForEach(Array(movies.enumerated()), id: \.element.id) { index, movie in
    MovieRow(movie: movie)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(
            .spring(response: 0.5, dampingFraction: 0.8)
                .delay(Double(index) * 0.05),
            value: appeared
        )
}
```

**Timing:** 0.05s delay per item, max 10 items staggered (0.5s total)

### Button Press

Subtle scale feedback on touch:

```swift
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
```

### Star Rating Animation

Stars fill sequentially with a golden glow:

```swift
ForEach(0..<5) { index in
    Image(systemName: index < rating ? "star.fill" : "star")
        .foregroundStyle(index < rating ? Color.cageGold : Color.starEmpty)
        .scaleEffect(index < rating ? 1.0 : 0.9)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.6)
                .delay(Double(index) * 0.1),
            value: rating
        )
}
```

### Ranking Reorder

Smooth drag-and-drop with haptic feedback:

```swift
.onDrag {
    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        isDragging = true
    }
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
    return NSItemProvider(object: movie.id.uuidString as NSString)
}
.onDrop(of: [.text], delegate: DropDelegate(...))
```

---

## Transition Patterns

### Screen Transitions

Use matched geometry for connected elements:

```swift
// Source (list)
AsyncImage(url: movie.posterURL)
    .matchedGeometryEffect(id: movie.id, in: namespace)

// Destination (detail)
AsyncImage(url: movie.posterURL)
    .matchedGeometryEffect(id: movie.id, in: namespace)
```

### Sheet Presentation

iOS 26 sheets have automatic Liquid Glass styling. Enhance with:

```swift
.sheet(isPresented: $showDetail) {
    MovieDetailView(movie: movie)
        .presentationBackground(.ultraThinMaterial)
        .presentationCornerRadius(24)
}
```

### Tab Transitions

Subtle cross-fade between tabs:

```swift
TabView(selection: $selectedTab) {
    // Tab content
}
.animation(.easeInOut(duration: 0.2), value: selectedTab)
```

---

## Gesture Animations

### Swipe to Dismiss

```swift
.gesture(
    DragGesture()
        .onChanged { value in
            withAnimation(.interactiveSpring()) {
                offset = value.translation
                opacity = 1 - (abs(value.translation.height) / 300)
            }
        }
        .onEnded { value in
            if abs(value.translation.height) > 100 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    dismiss()
                }
            } else {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    offset = .zero
                    opacity = 1
                }
            }
        }
)
```

### Pull to Refresh

Custom refresh indicator with Cage Gold spinner:

```swift
.refreshable {
    await viewModel.refresh()
}
// iOS handles the animation, we just provide the async action
```

### Carousel Snapping

```swift
ScrollView(.horizontal) {
    LazyHStack(spacing: 16) {
        ForEach(movies) { movie in
            RankingCard(movie: movie)
                .scrollTransition { content, phase in
                    content
                        .scaleEffect(phase.isIdentity ? 1 : 0.9)
                        .opacity(phase.isIdentity ? 1 : 0.7)
                }
        }
    }
    .scrollTargetLayout()
}
.scrollTargetBehavior(.viewAligned)
```

---

## Celebration Animations

### Achievement Unlock

Multi-layered celebration effect:

```swift
struct AchievementUnlockAnimation: View {
    @State private var scale = 0.5
    @State private var opacity = 0.0
    @State private var rotation = -10.0
    @State private var showConfetti = false

    var body: some View {
        ZStack {
            // Confetti particles (if desired)
            if showConfetti {
                ConfettiView()
            }

            // Achievement badge
            AchievementBadge(achievement: achievement)
                .scaleEffect(scale)
                .opacity(opacity)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            // Stage 1: Initial appearance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                scale = 1.1
                opacity = 1
                rotation = 0
            }

            // Stage 2: Settle
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8).delay(0.3)) {
                scale = 1.0
            }

            // Stage 3: Confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                showConfetti = true
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
    }
}
```

**Duration:** ~0.8s total, with haptic at 0.2s

### Milestone Reached

Subtle glow pulse for statistics milestones:

```swift
@State private var glowIntensity = 0.3

Text("\(watchCount)")
    .shadow(color: Color.cageGold.opacity(glowIntensity), radius: 20)
    .onAppear {
        if isNewMilestone {
            withAnimation(.easeInOut(duration: 0.8).repeatCount(3)) {
                glowIntensity = 0.8
            }
        }
    }
```

---

## Loading States

### Skeleton Loading

Shimmer effect for loading placeholders:

```swift
struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 300
                }
            }
    }
}
```

### Progress Indicator

Cage Gold spinning indicator:

```swift
struct GoldSpinner: View {
    @State private var rotation = 0.0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(Color.cageGold, lineWidth: 3)
            .frame(width: 30, height: 30)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
```

---

## Accessibility Considerations

### Reduce Motion Mode

```swift
struct SafeAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    let animation: Animation

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: UUID())
    }
}
```

### Provide Alternatives

When motion is reduced:
- Replace sliding transitions with cross-fades
- Disable parallax and spring effects
- Keep minimal feedback animations (opacity changes)
- Never remove functional animations entirely

```swift
var transition: AnyTransition {
    reduceMotion
        ? .opacity
        : .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
}
```

---

## Performance Guidelines

### Do's
- Use `withAnimation` for discrete state changes
- Prefer `.animation(_:value:)` for continuous changes
- Use `drawingGroup()` for complex composited views
- Profile animations with Instruments

### Don'ts
- Don't animate during network requests
- Don't use `.animation(.default)` (implicit animation on all changes)
- Don't exceed 0.5s for routine interactions
- Don't animate more than 10 items simultaneously

### Optimization Example

```swift
// Bad: Animates entire complex view
ComplexMovieCard(movie: movie)
    .animation(.spring(), value: isSelected)

// Good: Animate only what changes
ComplexMovieCard(movie: movie)
    .overlay(
        SelectionBorder()
            .opacity(isSelected ? 1 : 0)
            .animation(.spring(response: 0.3), value: isSelected)
    )
```

---

## Quick Reference

| Interaction | Animation | Duration | Spring |
|-------------|-----------|----------|--------|
| Button tap | Scale 0.96 | 0.2s | Quick |
| Card appear | Scale + Fade | 0.35s | Standard |
| List item | Staggered fade | 0.05s/item | Standard |
| Star fill | Sequential scale | 0.1s/star | Bouncy |
| Tab switch | Cross-fade | 0.2s | Ease |
| Sheet present | System default | Auto | System |
| Drag reorder | Interactive | Gesture | Interactive |
| Achievement | Multi-stage | 0.8s | Bouncy |
| Loading | Shimmer loop | 1.5s | Linear |

---

## Related Files

- `Constants.swift` - Animation duration constants
- `LiquidGlassComponents.swift` - Animated glass components
- `HapticManager.swift` - Coordinated haptic feedback
