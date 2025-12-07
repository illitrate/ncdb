// OnboardingSplashView.swift
// NCDB - Splash Screen
// Initial app launch screen with branding

import SwiftUI

struct OnboardingSplashView: View {
    let onComplete: () -> Void
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 24) {
                // App Icon
                Image("NCDBIcon")
                    .resizable()
                    .frame(width: 120, height: 120)
                    .opacity(opacity)
                
                // App Name
                Text("NCDB")
                    .font(.system(size: 48, weight: .bold, design: .default))
                    .foregroundStyle(Color(hex: "FFD700"))
                    .opacity(opacity)
            }
        }
        .onAppear {
            // Fade in animation
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1.0
            }
            
            // Auto-advance after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                onComplete()
            }
        }
    }
}

#Preview {
    OnboardingSplashView(onComplete: {})
}
