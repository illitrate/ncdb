//
//  FullScreenPosterView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-21.
//

import SwiftUI

/// Full-screen poster viewer with tap-to-dismiss, long-press-to-copy, and motion parallax effect
struct FullScreenPosterView: View {
    let posterPath: String
    let onDismiss: () -> Void

    @State private var showCopiedAlert = false
    @State private var loadedImage: UIImage?
    @State private var motionManager = MotionManager.shared

    private var fullSizePosterURL: URL? {
        URL(string: "\(TMDbConstants.imageBaseURL)/original\(posterPath)")
    }

    /// Calculate parallax offset and rotation based on device motion
    private var parallaxTransform: (xRotation: Angle, yRotation: Angle, xOffset: CGFloat, yOffset: CGFloat) {
        // Multiplier to control sensitivity (adjust for desired effect strength)
        let rotationMultiplier: Double = 15.0 // degrees
        let offsetMultiplier: CGFloat = 20.0 // points

        // Invert the motion for parallax effect (poster moves opposite to tilt)
        let xRotation = Angle(degrees: -motionManager.roll * rotationMultiplier)
        let yRotation = Angle(degrees: motionManager.pitch * rotationMultiplier)

        let xOffset = CGFloat(motionManager.roll) * offsetMultiplier
        let yOffset = CGFloat(-motionManager.pitch) * offsetMultiplier

        return (xRotation, yRotation, xOffset, yOffset)
    }

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Full-size poster with parallax effect
            CachedAsyncImage(url: fullSizePosterURL, placeholder: {
                ProgressView()
                    .tint(.cageGold)
                    .scaleEffect(1.5)
            }, content: { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .scaleEffect(1.1) // Slightly larger to prevent edge clipping during rotation
                    .rotation3DEffect(
                        parallaxTransform.xRotation,
                        axis: (x: 0, y: 1, z: 0)
                    )
                    .rotation3DEffect(
                        parallaxTransform.yRotation,
                        axis: (x: 1, y: 0, z: 0)
                    )
                    .offset(
                        x: parallaxTransform.xOffset,
                        y: parallaxTransform.yOffset
                    )
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: motionManager.pitch)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: motionManager.roll)
            })
            .onTapGesture {
                onDismiss()
            }
            .onLongPressGesture(minimumDuration: 0.5) {
                copyToClipboard()
            }
            .task {
                // Load image for clipboard functionality
                await loadImageForClipboard()
            }
            .onAppear {
                // Start motion tracking when view appears
                motionManager.startTracking()
            }
            .onDisappear {
                // Stop motion tracking when view disappears
                motionManager.stopTracking()
            }

            // "Copied!" alert
            if showCopiedAlert {
                VStack {
                    Spacer()

                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Poster copied to clipboard")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                    }
                    .padding(Spacing.md)
                    .background(Color.black.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Instruction overlay (subtle)
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: Spacing.xxs) {
                        Text("Tap to dismiss")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                        Text("Long-press to copy")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(Spacing.md)
                }
                Spacer()
            }
        }
    }

    private func loadImageForClipboard() async {
        guard let url = fullSizePosterURL else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    loadedImage = image
                }
            }
        } catch {
            Logger.shared.error("Failed to load image for clipboard: \(error)", category: .general)
        }
    }

    private func copyToClipboard() {
        guard let image = loadedImage else {
            // Try to load synchronously if not already loaded
            Task {
                await loadImageForClipboard()
                if let image = loadedImage {
                    UIPasteboard.general.image = image
                    showCopySuccess()
                }
            }
            return
        }

        UIPasteboard.general.image = image
        showCopySuccess()
    }

    private func showCopySuccess() {
        HapticManager.shared.success()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showCopiedAlert = true
        }

        // Hide alert after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedAlert = false
            }
        }
    }
}

#Preview {
    FullScreenPosterView(
        posterPath: "/sample-poster.jpg",
        onDismiss: {
            print("Dismissed")
        }
    )
}
