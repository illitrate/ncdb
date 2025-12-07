// RankingTutorialView.swift
// NCDB - Ranking Tutorial
// Interactive demo of carousel ranking system

import SwiftUI

struct RankingTutorialView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    @State private var showingInteractive = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Title
                Text("Master the Ranking Carousel")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                // Demo Area
                if showingInteractive {
                    InteractiveCarouselDemo()
                        .frame(height: 250)
                } else {
                    StaticCarouselDemo()
                        .frame(height: 250)
                }
                
                // Instructions
                VStack(spacing: 16) {
                    TutorialInstructionRow(
                        icon: "hand.draw",
                        text: "Swipe left or right to change rankings"
                    )
                    TutorialInstructionRow(
                        icon: "star.fill",
                        text: "The center film is always #1!"
                    )
                    TutorialInstructionRow(
                        icon: "arrow.left.arrow.right",
                        text: "Films shift position as you swipe"
                    )
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    if !showingInteractive {
                        Button {
                            withAnimation {
                                showingInteractive = true
                            }
                        } label: {
                            Text("Try It Now")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(hex: "FFD700"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    } else {
                        Button(action: onComplete) {
                            Text("Got It!")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(Color(hex: "FFD700"))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    
                    Button(action: onSkip) {
                        Text("Skip Tutorial")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}

struct TutorialInstructionRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "FFD700"))
                .font(.system(size: 20))
                .frame(width: 30)
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white)
            
            Spacer()
        }
    }
}

struct StaticCarouselDemo: View {
    var body: some View {
        HStack(spacing: 16) {
            // Left card (#2)
            DemoMovieCard(title: "Con Air", rank: 2, scale: 0.8)
            
            // Center card (#1)
            DemoMovieCard(title: "Face/Off", rank: 1, scale: 1.0)
            
            // Right card (#3)
            DemoMovieCard(title: "The Rock", rank: 3, scale: 0.8)
        }
        .padding()
    }
}

struct InteractiveCarouselDemo: View {
    @State private var currentIndex = 1
    let movies = ["Con Air", "Face/Off", "The Rock", "Raising Arizona"]
    
    var body: some View {
        TabView(selection: $currentIndex) {
            ForEach(0..<movies.count, id: \.self) { index in
                DemoMovieCard(
                    title: movies[index],
                    rank: index == currentIndex ? 1 : (index < currentIndex ? index + 1 : index),
                    scale: index == currentIndex ? 1.0 : 0.8
                )
                .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
    }
}

struct DemoMovieCard: View {
    let title: String
    let rank: Int
    let scale: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            // Rank badge
            Text("#\(rank)")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Color(hex: "FFD700"))
            
            // Movie poster placeholder
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 150)
                .overlay {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(8)
                }
        }
        .scaleEffect(scale)
        .animation(.spring(), value: scale)
    }
}

#Preview {
    RankingTutorialView(onComplete: {}, onSkip: {})
}
