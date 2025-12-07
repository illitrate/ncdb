// OnboardingWelcomeView.swift
// NCDB - Welcome Screen
// First interactive screen in onboarding

import SwiftUI

struct OnboardingWelcomeView: View {
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                Image("NCDBIcon")
                    .resizable()
                    .frame(width: 80, height: 80)
                
                // Title & Subtitle
                VStack(spacing: 12) {
                    Text("Welcome to NCDB")
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundStyle(.white)
                    
                    Text("Your Personal Nicolas Cage\nMovie Tracking Vault")
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                
                // Features List
                VStack(alignment: .leading, spacing: 16) {
                    OnboardingFeatureRow(text: "Track every Cage film")
                    OnboardingFeatureRow(text: "Rank your favorites")
                    OnboardingFeatureRow(text: "Share your reviews")
                    OnboardingFeatureRow(text: "Discover hidden gems")
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                
                Spacer()
                
                // Get Started Button
                Button(action: onContinue) {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(hex: "FFD700"))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
        }
    }
}

struct OnboardingFeatureRow: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(hex: "FFD700"))
                .font(.system(size: 20))
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

#Preview {
    OnboardingWelcomeView(onContinue: {})
}
