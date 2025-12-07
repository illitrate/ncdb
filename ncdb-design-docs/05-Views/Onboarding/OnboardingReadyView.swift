// OnboardingReadyView.swift
// NCDB - Onboarding Complete
// Final celebration screen before entering app

import SwiftUI

struct OnboardingReadyView: View {
    let onEnter: () -> Void
    let movieCount: Int = 127 // TODO: Pass actual count
    
    @State private var showContent = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Success Icon with Animation
                ZStack {
                    Circle()
                        .fill(Color(hex: "FFD700").opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(Color(hex: "FFD700"))
                }
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showContent)
                
                // Title & Message
                VStack(spacing: 12) {
                    Text("You're All Set!")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("Your vault is ready with \(movieCount) Nicolas Cage films.")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Text("Start watching, reviewing, and ranking your favorite Cage classics!")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                .opacity(showContent ? 1.0 : 0.0)
                .offset(y: showContent ? 0 : 20)
                .animation(.easeOut(duration: 0.5).delay(0.2), value: showContent)
                
                Spacer()
                
                // Enter App Button
                Button(action: onEnter) {
                    HStack {
                        Text("Enter NCDB")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(hex: "FFD700"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(showContent ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.5).delay(0.4), value: showContent)
            }
        }
        .onAppear {
            showContent = true
        }
    }
}

#Preview {
    OnboardingReadyView(onEnter: {})
}
