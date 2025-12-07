// NCDB Cache Manager
// Three-tier caching system: Memory ’ Disk ’ Network
// Optimized for movie metadata, images, and API responses

import Foundation
import SwiftUI

// MARK: - Cache Manager

/// Three-tier cache manager handling memory, disk, and network caching strategies
///
/// Cache Hierarchy:
/// 1. Memory Cache (NSCache) - Fastest, limited size, cleared on memory pressure
/// 2. Disk Cache (FileManager) - Persistent, larger capacity, expiration-based
/// 3. Network (TMDb API) - Fallback when cached data unavailable or expired
///
/// Usage:
/// ```swift
/// let cache = CacheManager.shared
///
/// // Cache movie metadata
/// await cache.cacheMetadata(movieDetails, forKey: "movie_\(movieID)")
///
/// // Retrieve with automatic tier fallback
/// let details = await cache.getMetadata(forKey: "movie_\(movieID)", type: TMDbMovieDetails.self)
/// ```
@Observable
final class CacheManager {

    // MARK: - Singleton
    static let shared = CacheManager()

    // MARK: - Memory Cache
    private let memoryCache = NSCache<NSString, CacheEntry>()

    // MARK: - Disk Cache
    private let fileManager = FileManager.default
    private lazy var cacheDirectory: URL = {
        let urls = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let cacheDir = urls[0].appendingPathComponent("NCDBCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
        return cacheDir
    }()

    // MARK: - Subdirectories
    private lazy var metadataDirectory: URL = {
        let dir = cacheDirectory.appendingPathComponent("metadata", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private lazy var imageDirectory: URL = {
        let dir = cacheDirectory.appendingPathComponent("images", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    private lazy var responseDirectory: URL = {
        let dir = cacheDirectory.appendingPathComponent("responses", isDirectory: true)
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    // MARK: - Configuration
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization

    private init() {
        configureMemoryCache()
        setupMemoryWarningObserver()
    }

    private func configureMemoryCache() {
        // Limit to ~50MB and 100 items
        memoryCache.totalCostLimit = CacheConstants.memoryCacheCostLimit
        memoryCache.countLimit = CacheConstants.memoryCacheCountLimit
    }

    private func setupMemoryWarningObserver() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearMemoryCache()
        }
        #endif
    }

    // MARK: - Generic Caching API

    /// Cache any Codable object with automatic expiration
    /// - Parameters:
    ///   - value: The Codable value to cache
    ///   - key: Unique cache key
    ///   - expiration: Time interval until expiration (default: 24 hours)
    ///   - tier: Which cache tiers to use
    func cache<T: Codable>(
        _ value: T,
        forKey key: String,
        expiration: TimeInterval = CacheConstants.metadataExpiration,
        tier: CacheTier = .all
    ) async {
        let entry = CacheEntry(
            data: try? encoder.encode(value),
            expiration: Date().addingTimeInterval(expiration),
            key: key
        )

        if tier.contains(.memory), let data = entry.data {
            memoryCache.setObject(entry, forKey: key as NSString, cost: data.count)
        }

        if tier.contains(.disk), let data = entry.data {
            await saveToDisk(data: data, key: key, directory: metadataDirectory, expiration: expiration)
        }
    }

    /// Retrieve a cached Codable object
    /// - Parameters:
    ///   - key: Cache key
    ///   - type: Expected type to decode
    /// - Returns: Cached value or nil if not found/expired
    func get<T: Codable>(forKey key: String, type: T.Type) async -> T? {
        // Tier 1: Memory Cache
        if let entry = memoryCache.object(forKey: key as NSString),
           !entry.isExpired,
           let data = entry.data,
           let value = try? decoder.decode(T.self, from: data) {
            return value
        }

        // Tier 2: Disk Cache
        if let data = await loadFromDisk(key: key, directory: metadataDirectory),
           let value = try? decoder.decode(T.self, from: data) {
            // Promote to memory cache
            let entry = CacheEntry(data: data, expiration: Date().addingTimeInterval(CacheConstants.metadataExpiration), key: key)
            memoryCache.setObject(entry, forKey: key as NSString, cost: data.count)
            return value
        }

        return nil
    }

    // MARK: - Movie Metadata Caching

    /// Cache movie details from TMDb
    func cacheMovieDetails(_ details: TMDbMovieDetails) async {
        let key = "movie_\(details.id)"
        await cache(details, forKey: key, expiration: CacheConstants.metadataExpiration)
    }

    /// Retrieve cached movie details
    func getMovieDetails(movieID: Int) async -> TMDbMovieDetails? {
        let key = "movie_\(movieID)"
        return await get(forKey: key, type: TMDbMovieDetails.self)
    }

    /// Cache the full Nicolas Cage filmography list
    func cacheFilmography(_ movies: [TMDbMovie]) async {
        await cache(movies, forKey: "cage_filmography", expiration: CacheConstants.metadataExpiration)
    }

    /// Retrieve cached filmography
    func getFilmography() async -> [TMDbMovie]? {
        return await get(forKey: "cage_filmography", type: [TMDbMovie].self)
    }

    // MARK: - Image Caching

    /// Cache an image to disk
    /// - Parameters:
    ///   - imageData: Raw image data (JPEG/PNG)
    ///   - key: Unique key (typically the TMDb path)
    func cacheImage(_ imageData: Data, forKey key: String) async {
        let sanitizedKey = sanitizeKey(key)
        await saveToDisk(data: imageData, key: sanitizedKey, directory: imageDirectory, expiration: CacheConstants.imageExpiration)
    }

    /// Retrieve a cached image
    /// - Parameter key: Image key (TMDb path)
    /// - Returns: Image data or nil
    func getImage(forKey key: String) async -> Data? {
        let sanitizedKey = sanitizeKey(key)
        return await loadFromDisk(key: sanitizedKey, directory: imageDirectory)
    }

    /// Get cached image as SwiftUI Image
    func getCachedSwiftUIImage(forKey key: String) async -> Image? {
        guard let data = await getImage(forKey: key) else { return nil }

        #if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #elseif os(macOS)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #endif
    }

    // MARK: - API Response Caching

    /// Cache a raw API response
    func cacheAPIResponse(_ data: Data, forKey key: String, expiration: TimeInterval = CacheConstants.searchExpiration) async {
        await saveToDisk(data: data, key: key, directory: responseDirectory, expiration: expiration)
    }

    /// Retrieve a cached API response
    func getAPIResponse(forKey key: String) async -> Data? {
        return await loadFromDisk(key: key, directory: responseDirectory)
    }

    // MARK: - Disk Operations

    private func saveToDisk(data: Data, key: String, directory: URL, expiration: TimeInterval) async {
        let fileURL = directory.appendingPathComponent(sanitizeKey(key))
        let metaURL = directory.appendingPathComponent("\(sanitizeKey(key)).meta")

        do {
            try data.write(to: fileURL)

            // Save expiration metadata
            let meta = CacheMetadata(expiration: Date().addingTimeInterval(expiration))
            let metaData = try encoder.encode(meta)
            try metaData.write(to: metaURL)
        } catch {
            print("Cache write error: \(error)")
        }
    }

    private func loadFromDisk(key: String, directory: URL) async -> Data? {
        let fileURL = directory.appendingPathComponent(sanitizeKey(key))
        let metaURL = directory.appendingPathComponent("\(sanitizeKey(key)).meta")

        // Check expiration
        if let metaData = try? Data(contentsOf: metaURL),
           let meta = try? decoder.decode(CacheMetadata.self, from: metaData) {
            if meta.isExpired {
                // Clean up expired files
                try? fileManager.removeItem(at: fileURL)
                try? fileManager.removeItem(at: metaURL)
                return nil
            }
        }

        return try? Data(contentsOf: fileURL)
    }

    // MARK: - Cache Management

    /// Clear all memory cache
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }

    /// Clear all disk cache
    func clearDiskCache() async {
        let directories = [metadataDirectory, imageDirectory, responseDirectory]
        for directory in directories {
            try? fileManager.removeItem(at: directory)
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
    }

    /// Clear all caches (memory + disk)
    func clearAllCaches() async {
        clearMemoryCache()
        await clearDiskCache()
    }

    /// Remove expired entries from disk cache
    func pruneExpiredEntries() async {
        let directories = [metadataDirectory, imageDirectory, responseDirectory]

        for directory in directories {
            guard let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil) else {
                continue
            }

            for file in files where file.pathExtension == "meta" {
                if let data = try? Data(contentsOf: file),
                   let meta = try? decoder.decode(CacheMetadata.self, from: data),
                   meta.isExpired {
                    // Remove both data and meta files
                    let dataFile = file.deletingPathExtension()
                    try? fileManager.removeItem(at: file)
                    try? fileManager.removeItem(at: dataFile)
                }
            }
        }
    }

    /// Calculate total disk cache size
    func diskCacheSize() async -> Int64 {
        var totalSize: Int64 = 0
        let directories = [metadataDirectory, imageDirectory, responseDirectory]

        for directory in directories {
            if let files = try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey]) {
                for file in files {
                    if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                        totalSize += Int64(size)
                    }
                }
            }
        }

        return totalSize
    }

    /// Formatted disk cache size string
    func formattedDiskCacheSize() async -> String {
        let size = await diskCacheSize()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    // MARK: - Cache Status

    /// Check if a key exists in cache (any tier)
    func exists(forKey key: String) async -> Bool {
        // Check memory
        if memoryCache.object(forKey: key as NSString) != nil {
            return true
        }

        // Check disk
        let fileURL = metadataDirectory.appendingPathComponent(sanitizeKey(key))
        return fileManager.fileExists(atPath: fileURL.path)
    }

    /// Remove a specific cached item
    func remove(forKey key: String) async {
        memoryCache.removeObject(forKey: key as NSString)

        let sanitized = sanitizeKey(key)
        let directories = [metadataDirectory, imageDirectory, responseDirectory]

        for directory in directories {
            let fileURL = directory.appendingPathComponent(sanitized)
            let metaURL = directory.appendingPathComponent("\(sanitized).meta")
            try? fileManager.removeItem(at: fileURL)
            try? fileManager.removeItem(at: metaURL)
        }
    }

    // MARK: - Helpers

    private func sanitizeKey(_ key: String) -> String {
        // Remove or replace characters that are invalid in filenames
        return key
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "?", with: "_")
            .replacingOccurrences(of: "&", with: "_")
    }
}

// MARK: - Supporting Types

/// Wrapper for cached data with expiration tracking
final class CacheEntry: NSObject {
    let data: Data?
    let expiration: Date
    let key: String

    var isExpired: Bool {
        Date() > expiration
    }

    init(data: Data?, expiration: Date, key: String) {
        self.data = data
        self.expiration = expiration
        self.key = key
    }
}

/// Metadata stored alongside cached files for expiration tracking
struct CacheMetadata: Codable {
    let expiration: Date

    var isExpired: Bool {
        Date() > expiration
    }
}

/// Options for which cache tiers to use
struct CacheTier: OptionSet {
    let rawValue: Int

    static let memory = CacheTier(rawValue: 1 << 0)
    static let disk = CacheTier(rawValue: 1 << 1)

    static let all: CacheTier = [.memory, .disk]
    static let memoryOnly: CacheTier = [.memory]
    static let diskOnly: CacheTier = [.disk]
}

// MARK: - Cache Statistics

extension CacheManager {
    /// Statistics about the current cache state
    struct CacheStats {
        let memoryCacheCount: Int
        let diskCacheSize: Int64
        let diskCacheSizeFormatted: String
        let metadataFileCount: Int
        let imageFileCount: Int
        let responseFileCount: Int
    }

    /// Get current cache statistics
    func getStats() async -> CacheStats {
        let size = await diskCacheSize()
        let formatted = await formattedDiskCacheSize()

        let metadataCount = (try? fileManager.contentsOfDirectory(at: metadataDirectory, includingPropertiesForKeys: nil).count) ?? 0
        let imageCount = (try? fileManager.contentsOfDirectory(at: imageDirectory, includingPropertiesForKeys: nil).count) ?? 0
        let responseCount = (try? fileManager.contentsOfDirectory(at: responseDirectory, includingPropertiesForKeys: nil).count) ?? 0

        return CacheStats(
            memoryCacheCount: memoryCache.countLimit, // Approximation
            diskCacheSize: size,
            diskCacheSizeFormatted: formatted,
            metadataFileCount: metadataCount / 2, // Divide by 2 to exclude .meta files
            imageFileCount: imageCount / 2,
            responseFileCount: responseCount / 2
        )
    }
}

// MARK: - Convenience Extensions

extension CacheManager {
    /// Cache with automatic key generation from TMDb movie ID
    func cacheForMovie<T: Codable>(_ value: T, movieID: Int, suffix: String = "") async {
        let key = suffix.isEmpty ? "movie_\(movieID)" : "movie_\(movieID)_\(suffix)"
        await cache(value, forKey: key)
    }

    /// Get cached data for a TMDb movie
    func getForMovie<T: Codable>(movieID: Int, suffix: String = "", type: T.Type) async -> T? {
        let key = suffix.isEmpty ? "movie_\(movieID)" : "movie_\(movieID)_\(suffix)"
        return await get(forKey: key, type: type)
    }
}
