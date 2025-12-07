// OnboardingHighlightsView.swift
// NCDB - Feature Highlights
// Swipeable screens showcasing key features

import SwiftUI

struct OnboardingHighlightsView: View {
    let onComplete: () -> Void
    @State private var currentPage = 0
    
    let highlights = [
        Highlight(
            icon: "film.stack",
            title: "Track Every Film",
            description: "Browse Nic Cage's entire filmography from The Movie Database. Mark films as watched, add ratings, and write personal reviews."
        ),
        Highlight(
            icon: "star.circle",
            title: "Rank Your Favorites",
            description: "Create custom rankings with our unique carousel interface. Drag and drop to reorder. Compare films side by side."
        ),
        Highlight(
            icon: "square.and.arrow.up",
            title: "Share & Discover",
            description: "Export your collection to the web. Share reviews on social media. Discover hidden gems and stay updated with Cage news."
        )
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<highlights.count, id: \.self) { index in
                        HighlightPage(highlight: highlights[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Custom page indicator
                HStack(spacing: 8) {
                    ForEach(0..<highlights.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color(hex: "FFD700") : Color.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                .padding(.bottom, 20)
                
                // Navigation Button
                Button {
                    if currentPage < highlights.count - 1 {
                        withAnimation {
                            currentPage += 1
                        }
                    } else {
                        onComplete()
                    }
                } label: {
                    Text(currentPage == highlights.count - 1 ? "Get Started" : "Next")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "FFD700"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct HighlightPage: View {
    let highlight: Highlight
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            Image(systemName: highlight.icon)
                .font(.system(size: 80))
                .foregroundStyle(Color(hex: "FFD700"))
            
            VStack(spacing: 12) {
                Text(highlight.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(highlight.description)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
    }
}

struct Highlight {
    let icon: String
    let title: String
    let description: String
}

#Preview {
    OnboardingHighlightsView(onComplete: {})
}
