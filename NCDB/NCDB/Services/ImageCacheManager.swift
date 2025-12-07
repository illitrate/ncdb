//
//  ImageCacheManager.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import UIKit

/// Manages in-memory and disk caching for TMDb images
/// Provides high-performance image caching with automatic memory management
@MainActor
final class ImageCacheManager {

    // MARK: - Singleton
    static let shared = ImageCacheManager()

    // MARK: - Properties

    /// In-memory cache for quick access
    private let memoryCache = NSCache<NSString, UIImage>()

    /// Disk cache directory
    private let diskCacheURL: URL

    /// File manager for disk operations
    private let fileManager = FileManager.default

    /// Maximum memory cache size (50 MB)
    private let maxMemoryCacheSize = 50 * 1024 * 1024

    /// Maximum disk cache size (200 MB)
    private let maxDiskCacheSize = 200 * 1024 * 1024

    /// Cache expiration time (7 days)
    private let cacheExpiration: TimeInterval = 7 * 24 * 60 * 60

    // MARK: - Initialization

    private init() {
        // Set up memory cache
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 100 // Max 100 images in memory

        // Set up disk cache directory
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = cachesDirectory.appendingPathComponent("ImageCache", isDirectory: true)

        // Create disk cache directory if needed
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)

        // Clean up expired cache on init
        Task {
            await cleanExpiredCache()
        }
    }

    // MARK: - Cache Key Generation

    /// Generate a cache key from a URL
    private func cacheKey(for url: URL) -> String {
        return url.absoluteString.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
    }

    // MARK: - Memory Cache Operations

    /// Store image in memory cache
    func cacheInMemory(_ image: UIImage, for url: URL) {
        let key = cacheKey(for: url) as NSString
        let cost = Int(image.size.width * image.size.height * 4) // Approximate bytes
        memoryCache.setObject(image, forKey: key, cost: cost)
    }

    /// Retrieve image from memory cache
    func imageFromMemory(for url: URL) -> UIImage? {
        let key = cacheKey(for: url) as NSString
        return memoryCache.object(forKey: key)
    }

    /// Clear all memory cache
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    // MARK: - Disk Cache Operations

    /// Get disk cache file URL for a given image URL
    private func diskCacheFileURL(for url: URL) -> URL {
        let key = cacheKey(for: url)
        return diskCacheURL.appendingPathComponent(key)
    }

    /// Store image on disk
    func cacheToDisk(_ image: UIImage, for url: URL) async {
        let fileURL = diskCacheFileURL(for: url)

        // Convert image to data
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }

        do {
            try data.write(to: fileURL)

            // Set file attributes with creation date for expiration checking
            let attributes: [FileAttributeKey: Any] = [
                .creationDate: Date()
            ]
            try fileManager.setAttributes(attributes, ofItemAtPath: fileURL.path)
        } catch {
            print("❌ Failed to cache image to disk: \(error.localizedDescription)")
        }
    }

    /// Retrieve image from disk cache
    func imageFromDisk(for url: URL) async -> UIImage? {
        let fileURL = diskCacheFileURL(for: url)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        // Check if file is expired
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let creationDate = attributes[.creationDate] as? Date {
                if Date().timeIntervalSince(creationDate) > cacheExpiration {
                    // File expired, delete it
                    try? fileManager.removeItem(at: fileURL)
                    return nil
                }
            }
        } catch {
            print("❌ Failed to check file attributes: \(error.localizedDescription)")
        }

        // Load image from disk
        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        // Also cache in memory for faster access next time
        cacheInMemory(image, for: url)

        return image
    }

    /// Clear all disk cache
    func clearDiskCache() async {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                try fileManager.removeItem(at: fileURL)
            }
            print("✅ Disk cache cleared successfully")
        } catch {
            print("❌ Failed to clear disk cache: \(error.localizedDescription)")
        }
    }

    /// Clean up expired cache files
    private func cleanExpiredCache() async {
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.creationDateKey])

            var deletedCount = 0
            for fileURL in fileURLs {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let creationDate = attributes[.creationDate] as? Date {
                    if Date().timeIntervalSince(creationDate) > cacheExpiration {
                        try fileManager.removeItem(at: fileURL)
                        deletedCount += 1
                    }
                }
            }

            if deletedCount > 0 {
                print("✅ Cleaned up \(deletedCount) expired cache files")
            }
        } catch {
            print("❌ Failed to clean expired cache: \(error.localizedDescription)")
        }
    }

    /// Get current disk cache size
    func diskCacheSize() async -> Int64 {
        var totalSize: Int64 = 0

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey])

            for fileURL in fileURLs {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
        } catch {
            print("❌ Failed to calculate disk cache size: \(error.localizedDescription)")
        }

        return totalSize
    }

    /// Trim disk cache if it exceeds maximum size
    func trimDiskCacheIfNeeded() async {
        let currentSize = await diskCacheSize()

        guard currentSize > maxDiskCacheSize else { return }

        do {
            // Get all files sorted by creation date (oldest first)
            let fileURLs = try fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey])

            let sortedFiles = try fileURLs.sorted { url1, url2 in
                let attr1 = try fileManager.attributesOfItem(atPath: url1.path)
                let attr2 = try fileManager.attributesOfItem(atPath: url2.path)
                let date1 = attr1[.creationDate] as? Date ?? Date.distantPast
                let date2 = attr2[.creationDate] as? Date ?? Date.distantPast
                return date1 < date2
            }

            // Delete oldest files until we're under the limit
            var sizeToFree = currentSize - Int64(maxDiskCacheSize)
            var deletedCount = 0

            for fileURL in sortedFiles {
                guard sizeToFree > 0 else { break }

                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = attributes[.size] as? Int64 {
                    try fileManager.removeItem(at: fileURL)
                    sizeToFree -= fileSize
                    deletedCount += 1
                }
            }

            print("✅ Trimmed disk cache: deleted \(deletedCount) files")
        } catch {
            print("❌ Failed to trim disk cache: \(error.localizedDescription)")
        }
    }

    // MARK: - Unified Cache Operations

    /// Get image from cache (memory first, then disk)
    func getCachedImage(for url: URL) async -> UIImage? {
        // Check memory cache first
        if let memoryImage = imageFromMemory(for: url) {
            return memoryImage
        }

        // Check disk cache
        if let diskImage = await imageFromDisk(for: url) {
            return diskImage
        }

        return nil
    }

    /// Cache image to both memory and disk
    func cacheImage(_ image: UIImage, for url: URL) async {
        cacheInMemory(image, for: url)
        await cacheToDisk(image, for: url)
    }

    /// Clear all caches (memory and disk)
    func clearAllCaches() async {
        clearMemoryCache()
        await clearDiskCache()
    }

    /// Get formatted cache size string
    func formattedCacheSize() async -> String {
        let bytes = await diskCacheSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
