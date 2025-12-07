//
//  ImageLoader.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import Combine

/// Observable image loader with caching support
/// Handles async image loading from TMDb with automatic caching
@MainActor
@Observable
final class ImageLoader {

    // MARK: - Properties

    /// The loaded image
    private(set) var image: UIImage?

    /// Loading state
    private(set) var isLoading = false

    /// Error state
    private(set) var error: Error?

    /// The image URL
    private var imageURL: URL?

    /// Cache manager
    private let cacheManager = ImageCacheManager.shared

    /// Current download task
    nonisolated(unsafe) private var downloadTask: Task<Void, Never>?

    // MARK: - Initialization

    init() {}

    deinit {
        downloadTask?.cancel()
    }

    // MARK: - Loading

    /// Load image from URL
    /// - Parameter url: The image URL to load
    func load(from url: URL?) async {
        // Cancel any existing download
        cancel()

        guard let url = url else {
            self.image = nil
            return
        }

        // Check if we're already loading this URL
        if imageURL == url, image != nil {
            return
        }

        imageURL = url
        isLoading = true
        error = nil

        downloadTask = Task {
            do {
                // Check cache first
                if let cachedImage = await cacheManager.getCachedImage(for: url) {
                    self.image = cachedImage
                    self.isLoading = false
                    return
                }

                // Download image
                let (data, response) = try await URLSession.shared.data(from: url)

                // Validate response
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw ImageLoaderError.invalidResponse
                }

                // Convert to UIImage
                guard let downloadedImage = UIImage(data: data) else {
                    throw ImageLoaderError.invalidImageData
                }

                // Cache the image
                await cacheManager.cacheImage(downloadedImage, for: url)

                // Update UI
                if !Task.isCancelled {
                    self.image = downloadedImage
                    self.isLoading = false
                }
            } catch {
                if !Task.isCancelled {
                    self.error = error
                    self.isLoading = false
                    print("❌ Image loading failed: \(error.localizedDescription)")
                }
            }
        }

        await downloadTask?.value
    }

    /// Cancel the current download
    func cancel() {
        downloadTask?.cancel()
        downloadTask = nil
    }

    /// Reset the loader
    func reset() {
        cancel()
        image = nil
        error = nil
        isLoading = false
        imageURL = nil
    }
}

// MARK: - Errors

enum ImageLoaderError: LocalizedError {
    case invalidResponse
    case invalidImageData

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .invalidImageData:
            return "Unable to load image data"
        }
    }
}

// MARK: - SwiftUI View Extension

extension View {
    /// Load and display a cached image with placeholder and error handling
    func cachedAsyncImage(
        url: URL?,
        placeholder: @escaping () -> some View = { Color.gray.opacity(0.3) },
        content: @escaping (Image) -> some View = { $0.resizable() }
    ) -> some View {
        CachedAsyncImage(url: url, placeholder: placeholder, content: content)
    }
}

// MARK: - Cached Async Image View

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let placeholder: () -> Placeholder
    let content: (Image) -> Content

    @State private var loader = ImageLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                content(Image(uiImage: image))
            } else if loader.isLoading {
                placeholder()
                    .overlay {
                        ProgressView()
                    }
            } else if loader.error != nil {
                placeholder()
                    .overlay {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundStyle(.secondary)
                    }
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loader.load(from: url)
        }
    }
}

// MARK: - Shimmer Effect for Loading States

extension View {
    /// Apply a shimmer loading effect
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            .clear,
                            .white.opacity(0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: phase * geometry.size.width * 2 - geometry.size.width)
                }
                .allowsHitTesting(false)
            }
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}
