// NCDB Image Loader
// Efficient image loading with caching and prefetching

import Foundation
import SwiftUI
import UIKit

// MARK: - Image Loader

/// High-performance image loader with multi-tier caching
///
/// Features:
/// - Memory cache (NSCache) for fast access
/// - Disk cache for persistence
/// - Automatic cache eviction
/// - Prefetching support
/// - Cancellation handling
/// - Progressive loading
/// - Error recovery with retry
///
/// Usage:
/// ```swift
/// let loader = ImageLoader.shared
///
/// // Load an image
/// let image = try await loader.loadImage(from: url)
///
/// // Prefetch images
/// loader.prefetch(urls: posterURLs)
/// ```
@MainActor
@Observable
final class ImageLoader {

    // MARK: - Singleton

    static let shared = ImageLoader()

    // MARK: - Configuration

    struct Configuration {
        var memoryCacheLimit: Int = 100 * 1024 * 1024 // 100 MB
        var diskCacheLimit: Int = 500 * 1024 * 1024   // 500 MB
        var diskCacheMaxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        var maxConcurrentDownloads: Int = 4
        var timeoutInterval: TimeInterval = 30
        var retryCount: Int = 2
        var retryDelay: TimeInterval = 1.0
    }

    var configuration = Configuration()

    // MARK: - Caches

    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    private let fileManager = FileManager.default

    // MARK: - Networking

    private let session: URLSession
    private var activeTasks: [URL: Task<UIImage, Error>] = [:]
    private let taskQueue = DispatchQueue(label: "com.ncdb.imageloader", attributes: .concurrent)

    // MARK: - State

    var isLoading = false
    var loadingCount = 0

    // MARK: - Statistics

    private(set) var cacheHits = 0
    private(set) var cacheMisses = 0
    private(set) var downloadCount = 0

    // MARK: - Initialization

    private init() {
        // Configure memory cache
        memoryCache.totalCostLimit = configuration.memoryCacheLimit
        memoryCache.countLimit = 200

        // Configure disk cache directory
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        diskCacheURL = cacheDirectory.appendingPathComponent("NCDBImageCache", isDirectory: true)

        // Create disk cache directory if needed
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        // Configure URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = configuration.timeoutInterval
        config.httpMaximumConnectionsPerHost = configuration.maxConcurrentDownloads
        config.requestCachePolicy = .returnCacheDataElseLoad
        session = URLSession(configuration: config)

        // Schedule cache cleanup
        scheduleCacheCleanup()
    }

    // MARK: - Public API

    /// Load an image from URL
    func loadImage(from url: URL) async throws -> UIImage {
        // Check memory cache first
        let cacheKey = cacheKey(for: url)
        if let cached = memoryCache.object(forKey: cacheKey as NSString) {
            cacheHits += 1
            return cached
        }

        // Check disk cache
        if let diskCached = loadFromDisk(url: url) {
            memoryCache.setObject(diskCached, forKey: cacheKey as NSString, cost: diskCached.memoryCost)
            cacheHits += 1
            return diskCached
        }

        cacheMisses += 1

        // Check for existing download task
        if let existingTask = activeTasks[url] {
            return try await existingTask.value
        }

        // Start new download
        let task = Task<UIImage, Error> {
            try await downloadImage(from: url)
        }

        activeTasks[url] = task

        do {
            let image = try await task.value
            activeTasks.removeValue(forKey: url)

            // Cache the result
            memoryCache.setObject(image, forKey: cacheKey as NSString, cost: image.memoryCost)
            saveToDisk(image: image, url: url)

            return image
        } catch {
            activeTasks.removeValue(forKey: url)
            throw error
        }
    }

    /// Load image with placeholder
    func loadImage(from url: URL, placeholder: UIImage) async -> UIImage {
        do {
            return try await loadImage(from: url)
        } catch {
            return placeholder
        }
    }

    /// Prefetch images for later use
    func prefetch(urls: [URL]) {
        for url in urls {
            // Skip if already cached
            let cacheKey = cacheKey(for: url)
            if memoryCache.object(forKey: cacheKey as NSString) != nil {
                continue
            }

            // Start background fetch
            Task(priority: .background) {
                _ = try? await loadImage(from: url)
            }
        }
    }

    /// Cancel prefetching for URLs
    func cancelPrefetch(urls: [URL]) {
        for url in urls {
            activeTasks[url]?.cancel()
            activeTasks.removeValue(forKey: url)
        }
    }

    /// Check if image is cached
    func isCached(url: URL) -> Bool {
        let cacheKey = cacheKey(for: url)
        if memoryCache.object(forKey: cacheKey as NSString) != nil {
            return true
        }
        return diskCacheFileExists(url: url)
    }

    /// Get cached image synchronously (memory only)
    func getCachedImage(url: URL) -> UIImage? {
        let cacheKey = cacheKey(for: url)
        return memoryCache.object(forKey: cacheKey as NSString)
    }

    // MARK: - Download

    private func downloadImage(from url: URL, attempt: Int = 0) async throws -> UIImage {
        loadingCount += 1
        defer { loadingCount -= 1 }

        do {
            let (data, response) = try await session.data(from: url)

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw ImageLoaderError.invalidResponse
            }

            guard let image = UIImage(data: data) else {
                throw ImageLoaderError.invalidImageData
            }

            downloadCount += 1
            return image

        } catch {
            // Retry logic
            if attempt < configuration.retryCount {
                try await Task.sleep(nanoseconds: UInt64(configuration.retryDelay * 1_000_000_000))
                return try await downloadImage(from: url, attempt: attempt + 1)
            }

            throw ImageLoaderError.downloadFailed(error)
        }
    }

    // MARK: - Memory Cache

    /// Clear memory cache
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    // MARK: - Disk Cache

    private func cacheKey(for url: URL) -> String {
        url.absoluteString.md5Hash
    }

    private func diskCacheFile(for url: URL) -> URL {
        let filename = cacheKey(for: url)
        return diskCacheURL.appendingPathComponent(filename)
    }

    private func diskCacheFileExists(url: URL) -> Bool {
        let file = diskCacheFile(for: url)
        return fileManager.fileExists(atPath: file.path)
    }

    private func loadFromDisk(url: URL) -> UIImage? {
        let file = diskCacheFile(for: url)

        guard fileManager.fileExists(atPath: file.path),
              let data = try? Data(contentsOf: file),
              let image = UIImage(data: data) else {
            return nil
        }

        // Check if file is too old
        if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
           let modificationDate = attributes[.modificationDate] as? Date {
            let age = Date().timeIntervalSince(modificationDate)
            if age > configuration.diskCacheMaxAge {
                try? fileManager.removeItem(at: file)
                return nil
            }
        }

        return image
    }

    private func saveToDisk(image: UIImage, url: URL) {
        let file = diskCacheFile(for: url)

        // Determine format based on URL
        let data: Data?
        if url.pathExtension.lowercased() == "png" {
            data = image.pngData()
        } else {
            data = image.jpegData(compressionQuality: 0.9)
        }

        guard let imageData = data else { return }

        Task.detached(priority: .background) {
            try? imageData.write(to: file)
        }
    }

    /// Clear disk cache
    func clearDiskCache() {
        try? fileManager.removeItem(at: diskCacheURL)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }

    /// Clear all caches
    func clearAllCaches() {
        clearMemoryCache()
        clearDiskCache()
        cacheHits = 0
        cacheMisses = 0
        downloadCount = 0
    }

    /// Get disk cache size
    func getDiskCacheSize() -> Int64 {
        var size: Int64 = 0

        guard let enumerator = fileManager.enumerator(
            at: diskCacheURL,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        ) else { return 0 }

        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size += Int64(fileSize)
            }
        }

        return size
    }

    // MARK: - Cache Cleanup

    private func scheduleCacheCleanup() {
        Task.detached(priority: .background) { [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: 60 * 60 * 1_000_000_000) // Every hour
                await self?.cleanupDiskCache()
            }
        }
    }

    private func cleanupDiskCache() async {
        guard let enumerator = fileManager.enumerator(
            at: diskCacheURL,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey],
            options: .skipsHiddenFiles
        ) else { return }

        var cacheFiles: [(url: URL, date: Date, size: Int)] = []

        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey]),
                  let date = values.contentModificationDate,
                  let size = values.fileSize else { continue }

            // Remove expired files
            let age = Date().timeIntervalSince(date)
            if age > configuration.diskCacheMaxAge {
                try? fileManager.removeItem(at: fileURL)
                continue
            }

            cacheFiles.append((fileURL, date, size))
        }

        // If over size limit, remove oldest files
        let totalSize = cacheFiles.reduce(0) { $0 + $1.size }
        if totalSize > configuration.diskCacheLimit {
            let sorted = cacheFiles.sorted { $0.date < $1.date }
            var sizeToRemove = totalSize - configuration.diskCacheLimit

            for file in sorted {
                guard sizeToRemove > 0 else { break }
                try? fileManager.removeItem(at: file.url)
                sizeToRemove -= file.size
            }
        }
    }

    // MARK: - Statistics

    var cacheHitRate: Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0 }
        return Double(cacheHits) / Double(total)
    }

    func resetStatistics() {
        cacheHits = 0
        cacheMisses = 0
        downloadCount = 0
    }
}

// MARK: - Async Image View

/// SwiftUI view for async image loading with caching
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var image: UIImage?
    @State private var isLoading = false

    init(
        url: URL?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let image {
                content(Image(uiImage: image))
            } else {
                placeholder()
                    .task(id: url) {
                        await loadImage()
                    }
            }
        }
    }

    private func loadImage() async {
        guard let url, !isLoading else { return }

        isLoading = true
        defer { isLoading = false }

        image = try? await ImageLoader.shared.loadImage(from: url)
    }
}

// MARK: - Poster Image View

/// Specialized image view for movie posters
struct PosterImage: View {
    let path: String?
    let size: PosterSize

    init(path: String?, size: PosterSize = .w500) {
        self.path = path
        self.size = size
    }

    var url: URL? {
        guard let path else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size.rawValue)\(path)")
    }

    var body: some View {
        CachedAsyncImage(url: url) { image in
            image
                .resizable()
                .aspectRatio(2/3, contentMode: .fill)
        } placeholder: {
            Rectangle()
                .fill(Color.secondaryBackground)
                .aspectRatio(2/3, contentMode: .fill)
                .overlay {
                    Image(systemName: "film")
                        .font(.largeTitle)
                        .foregroundStyle(.tertiary)
                }
        }
    }
}

// MARK: - Prefetch Modifier

/// View modifier for prefetching images
struct PrefetchImagesModifier: ViewModifier {
    let urls: [URL]

    func body(content: Content) -> some View {
        content
            .onAppear {
                ImageLoader.shared.prefetch(urls: urls)
            }
            .onDisappear {
                ImageLoader.shared.cancelPrefetch(urls: urls)
            }
    }
}

extension View {
    func prefetchImages(_ urls: [URL]) -> some View {
        modifier(PrefetchImagesModifier(urls: urls))
    }
}

// MARK: - Errors

enum ImageLoaderError: LocalizedError {
    case invalidURL
    case invalidResponse
    case invalidImageData
    case downloadFailed(Error)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid image URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .invalidImageData:
            return "Could not decode image data"
        case .downloadFailed(let error):
            return "Download failed: \(error.localizedDescription)"
        case .cancelled:
            return "Image download was cancelled"
        }
    }
}

// MARK: - Extensions

extension UIImage {
    /// Approximate memory cost of the image
    var memoryCost: Int {
        guard let cgImage = self.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}

extension String {
    /// Simple MD5 hash for cache keys
    var md5Hash: String {
        let data = Data(self.utf8)
        var hash = [UInt8](repeating: 0, count: 16)

        data.withUnsafeBytes { buffer in
            _ = CC_MD5(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }

        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// Note: For MD5, import CommonCrypto or use CryptoKit
import CommonCrypto
