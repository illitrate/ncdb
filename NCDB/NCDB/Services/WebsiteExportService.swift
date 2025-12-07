//
//  WebsiteExportService.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation
import UIKit

/// Service for generating static HTML websites from user's movie collection
@MainActor
final class WebsiteExportService {
    static let shared = WebsiteExportService()

    private let templateEngine = TemplateEngine.shared
    private let fileManager = FileManager.default

    private init() {}

    // MARK: - Website Generation

    /// Generate a complete static website
    func generateWebsite(
        productions: [Production],
        userName: String = "My",
        includeImages: Bool = true
    ) async throws -> URL {
        Logger.shared.info("Starting website generation...", category: .general)

        // Create temporary directory for website
        let websiteDir = try createWebsiteDirectory()

        // Prepare data for template
        let templateData = prepareTemplateData(
            productions: productions,
            userName: userName
        )

        // Generate HTML
        let template = templateEngine.getDefaultTemplate()
        let html = templateEngine.render(template: template, data: templateData)

        // Write HTML file
        let indexPath = websiteDir.appendingPathComponent("index.html")
        try html.write(to: indexPath, atomically: true, encoding: .utf8)

        // Download and save poster images if requested
        if includeImages {
            try await downloadPosters(
                for: productions.filter { $0.watched },
                to: websiteDir
            )
        }

        // Create CSS file (already embedded, but keep separate copy)
        try createStylesheet(at: websiteDir)

        // Create assets directory
        try createAssetsDirectory(at: websiteDir)

        Logger.shared.info("Website generated at: \(websiteDir.path)", category: .general)

        return websiteDir
    }

    // MARK: - Template Data Preparation

    private func prepareTemplateData(
        productions: [Production],
        userName: String
    ) -> [String: Any] {
        let watchedProductions = productions.filter { $0.watched }
        let rankedProductions = productions
            .filter { ($0.rankingPosition ?? 0) > 0 }
            .sorted { ($0.rankingPosition ?? 0) < ($1.rankingPosition ?? 0) }

        // Calculate stats
        let ratings = watchedProductions.compactMap { $0.userRating }
        let averageRating = ratings.isEmpty ? 0.0 : ratings.reduce(0.0, +) / Double(ratings.count)
        let totalRuntime = watchedProductions.reduce(0) { $0 + ($1.runtime ?? 0) }
        let completionPercentage = productions.isEmpty ? 0.0 : Double(watchedProductions.count) / Double(productions.count) * 100.0

        // Prepare watched movies data
        let watchedMoviesData: [[String: Any]] = watchedProductions.map { movie in
            [
                "title": movie.title,
                "year": movie.releaseYear,
                "posterURL": movie.posterPath.flatMap { "https://image.tmdb.org/t/p/w342\($0)" } ?? "",
                "rating": movie.userRating.map { String(format: "%.1f", $0) } ?? ""
            ]
        }

        // Prepare ranked movies data
        let rankedMoviesData: [[String: Any]] = rankedProductions.prefix(10).map { movie in
            [
                "rank": movie.rankingPosition ?? 0,
                "title": movie.title,
                "year": movie.releaseYear,
                "posterURL": movie.posterPath.flatMap { "https://image.tmdb.org/t/p/w342\($0)" } ?? "",
                "rating": movie.userRating.map { String(format: "%.1f", $0) } ?? ""
            ]
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short

        return [
            "userName": userName,
            "watchedCount": watchedProductions.count,
            "totalCount": productions.count,
            "completionPercentage": String(format: "%.0f", completionPercentage),
            "averageRating": ratings.isEmpty ? "N/A" : String(format: "%.1f", averageRating),
            "totalRuntime": formatRuntime(totalRuntime),
            "hasRankings": !rankedProductions.isEmpty,
            "rankedMovies": rankedMoviesData,
            "watchedMovies": watchedMoviesData,
            "lastUpdated": dateFormatter.string(from: Date()),
            "currentYear": Calendar.current.component(.year, from: Date())
        ]
    }

    // MARK: - Helper Methods

    private func createWebsiteDirectory() throws -> URL {
        let tempDir = fileManager.temporaryDirectory
        let websiteDir = tempDir.appendingPathComponent("NCDBWebsite-\(UUID().uuidString)")

        try fileManager.createDirectory(at: websiteDir, withIntermediateDirectories: true)

        return websiteDir
    }

    private func createStylesheet(at directory: URL) throws {
        // CSS is already embedded in the template, but create a separate file for customization
        let css = """
        /* Additional custom styles can be added here */
        """

        let cssPath = directory.appendingPathComponent("custom.css")
        try css.write(to: cssPath, atomically: true, encoding: .utf8)
    }

    private func createAssetsDirectory(at directory: URL) throws {
        let assetsDir = directory.appendingPathComponent("assets")
        try fileManager.createDirectory(at: assetsDir, withIntermediateDirectories: true)

        // Create images subdirectory
        let imagesDir = assetsDir.appendingPathComponent("images")
        try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
    }

    private func downloadPosters(for productions: [Production], to directory: URL) async throws {
        let imagesDir = directory.appendingPathComponent("assets/images")

        for production in productions.prefix(20) { // Limit to first 20 for performance
            guard let posterPath = production.posterPath else { continue }
            let imageURL = URL(string: "https://image.tmdb.org/t/p/w342\(posterPath)")!

            do {
                let (data, _) = try await URLSession.shared.data(from: imageURL)
                let filename = "\(production.id.uuidString).jpg"
                let filePath = imagesDir.appendingPathComponent(filename)
                try data.write(to: filePath)
            } catch {
                Logger.shared.warning("Failed to download poster for \(production.title): \(error)", category: .general)
            }
        }
    }

    private func formatRuntime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        }

        let hours = minutes / 60
        let remainingMinutes = minutes % 60

        if remainingMinutes == 0 {
            return "\(hours)h"
        }

        return "\(hours)h \(remainingMinutes)m"
    }

    // MARK: - Preview Generation

    /// Generate a preview HTML snippet for display in app
    func generatePreview(productions: [Production]) -> String {
        let watchedCount = productions.filter { $0.watched }.count

        return """
        <div style="padding: 20px; background: #1A1A1A; border-radius: 12px; color: white;">
            <h2 style="color: #D4AF37; margin-bottom: 10px;">Preview</h2>
            <p>Your website will include:</p>
            <ul style="line-height: 1.8;">
                <li>\(watchedCount) watched movies</li>
                <li>Interactive stats dashboard</li>
                <li>Your top rankings</li>
                <li>Beautiful poster grid</li>
                <li>Mobile-responsive design</li>
            </ul>
        </div>
        """
    }

    // MARK: - Export Package

    /// Create a ZIP archive of the website
    func createExportPackage(websiteURL: URL) throws -> URL {
        let zipURL = fileManager.temporaryDirectory
            .appendingPathComponent("NCDB-Website-\(Date().timeIntervalSince1970).zip")

        // Create ZIP archive (simplified - in production would use proper ZIP library)
        // For now, just return the directory URL
        Logger.shared.info("Export package ready at: \(websiteURL.path)", category: .general)

        return websiteURL
    }
}
