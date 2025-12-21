//
//  NCDBLogoView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-08.
//

import SwiftUI

/// Enhanced NCDB logo with embossed effects and metallic gradient
/// Designed to be tappable and placed in navigation bar center
struct NCDBLogoView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            onTap()
        }) {
            Text("NCDB")
                .font(.system(size: 36, weight: .black, design: .rounded))
                .foregroundStyle(metallicGoldGradient)
                // Embossed effect: dark shadow below (recessed look)
                .shadow(color: .black.opacity(0.6), radius: 2, x: 3, y: 5)
                // Light highlight above (raised edge)
                .shadow(color: .white.opacity(0.3), radius: 1, x: 0, y: -1)
                // Outer glow for premium feel
//                .shadow(color: .cageGold.opacity(0.3), radius: 8, x: 2, y: 2)
                // Additional depth shadow
                .shadow(color: .cageGold.opacity(0.1), radius: 16, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("NCDB Logo")
        .accessibilityHint("Tap to view app information and help")
    }

    /// Metallic gold gradient with multiple color stops for depth
    private var metallicGoldGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.95, blue: 0.6),   // Light gold highlight
                Color.cageGold,                             // Main gold
                Color(red: 0.9, green: 0.75, blue: 0.0),    // Darker gold
                Color.cageGold,                             // Main gold
                Color(red: 1.0, green: 0.95, blue: 0.6)     // Light gold highlight
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    VStack {
        // On dark background (app's primary color)
        NCDBLogoView {
            print("Logo tapped")
        }
        .padding()
        .background(Color.black)

        Spacer()
            .frame(height: 40)

        // In navigation bar context
        NavigationStack {
            Color.primaryBackground
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        NCDBLogoView {
                            print("Logo tapped")
                        }
                    }
                }
        }
    }
    .background(Color.primaryBackground)
}
