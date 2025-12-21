//
//  NCDBHeaderView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-08.
//

import SwiftUI

/// Global NCDB header with app branding and tap-to-show-About functionality
struct NCDBHeaderView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.shared.buttonTap()
            onTap()
        }) {
            HStack(spacing: Spacing.sm) {
                // App Icon
                Image("AppIcon")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // NCDB Text
                Text("NCDB")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cageGold, .cageGold.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .cageGold.opacity(0.3), radius: 8)

                Spacer()
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .frame(height: 60)
            .background(.ultraThinMaterial)
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundStyle(.white.opacity(0.1)),
                alignment: .bottom
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("About NCDB")
        .accessibilityHint("Tap to view app information and help")
    }
}

/// Button style with scale animation on press
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 0) {
        NCDBHeaderView {
            print("Header tapped")
        }

        Spacer()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.primaryBackground)
    }
}
