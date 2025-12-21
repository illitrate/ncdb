//
//  FullScreenPosterView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-21.
//

import SwiftUI

/// Full-screen poster viewer with tap-to-dismiss and long-press-to-copy
struct FullScreenPosterView: View {
    let posterPath: String
    let onDismiss: () -> Void

    @State private var showCopiedAlert = false
    @State private var loadedImage: UIImage?

    private var fullSizePosterURL: URL? {
        URL(string: "\(TMDbConstants.imageBaseURL)/original\(posterPath)")
    }

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            // Full-size poster
            CachedAsyncImage(url: fullSizePosterURL, placeholder: {
                ProgressView()
                    .tint(.cageGold)
                    .scaleEffect(1.5)
            }, content: { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
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
