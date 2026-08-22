// NCDB Schema Versioning
// Declares the persisted schema, how it migrates, and how the store is opened.
//
// The rule this file exists to enforce: NCDB never deletes a user's library
// without being asked to. A store that fails to open is preserved and moved
// aside, never removed.

import Foundation
import SwiftData

// MARK: - Versioned Schema

/// The schema as shipped in NCDB 1.x and 2.0.
///
/// When you change a model, add a new `NCDBSchemaVn` below and append it to
/// `NCDBMigrationPlan.schemas`. Additive changes (a new property with a default,
/// a new model) are handled by SwiftData's lightweight migration and need no
/// stage. Renames, type changes and data reshaping need an explicit
/// `MigrationStage.custom` in `NCDBMigrationPlan.stages`.
enum NCDBSchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(1, 0, 0) }

    static var models: [any PersistentModel.Type] {
        [
            Production.self,
            CastMember.self,
            WatchEvent.self,
            ExternalRating.self,
            CustomTag.self,
            NewsArticle.self,
            Achievement.self,
            UserPreferences.self,
            ExportTemplate.self
        ]
    }
}

// MARK: - Migration Plan

enum NCDBMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [NCDBSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}

// MARK: - Container Loading

/// Opens the NCDB store. Failures are reported, never papered over by deleting data.
enum NCDBModelContainer {

    /// The schema the app is built against.
    static var schema: Schema {
        Schema(versionedSchema: NCDBSchemaV1.self)
    }

    // MARK: Configuration

    static func configuration(inMemory: Bool = false) -> ModelConfiguration {
        ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: true
        )
    }

    /// On-disk location of the store, used by the recovery flow.
    static var storeURL: URL {
        configuration().url
    }

    /// The store file plus its write-ahead log siblings.
    private static func storeFileURLs(for url: URL) -> [URL] {
        let base = url.deletingPathExtension()
        return [
            url,
            base.appendingPathExtension("sqlite-shm"),
            base.appendingPathExtension("sqlite-wal")
        ]
    }

    // MARK: Loading

    /// Open the persistent store, running the migration plan.
    /// - Throws: the underlying SwiftData error if the store cannot be opened.
    static func load(inMemory: Bool = false) throws -> ModelContainer {
        let container = try ModelContainer(
            for: schema,
            migrationPlan: NCDBMigrationPlan.self,
            configurations: [configuration(inMemory: inMemory)]
        )
        Logger.shared.info("Model container opened (schema \(NCDBSchemaV1.versionIdentifier))", category: .database)
        return container
    }

    /// A throwaway in-memory container, so the recovery UI and previews can run
    /// even when the real store is unreadable. Nothing written here is persisted.
    static func ephemeral() -> ModelContainer? {
        try? ModelContainer(for: schema, configurations: [configuration(inMemory: true)])
    }

    // MARK: Recovery

    /// Whether a store file exists on disk at all.
    static var storeExists: Bool {
        FileManager.default.fileExists(atPath: storeURL.path)
    }

    /// Size of the store on disk, for display in the recovery screen.
    static var storeSizeDescription: String {
        let total = storeFileURLs(for: storeURL).reduce(Int64(0)) { running, url in
            guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                  let size = attributes[.size] as? Int64 else { return running }
            return running + size
        }
        guard total > 0 else { return "unknown size" }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }

    /// Move the unreadable store into a timestamped folder alongside it and
    /// return that folder, so a fresh store can be created without losing the old one.
    ///
    /// This is the *only* path in the app that takes the user's library out of
    /// play, and it is only ever called after explicit confirmation.
    @discardableResult
    static func archiveStore() throws -> URL {
        let fileManager = FileManager.default
        let url = storeURL

        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let archiveDirectory = url
            .deletingLastPathComponent()
            .appendingPathComponent("RecoveredStores/\(stamp)", isDirectory: true)

        try fileManager.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)

        for fileURL in storeFileURLs(for: url) where fileManager.fileExists(atPath: fileURL.path) {
            let destination = archiveDirectory.appendingPathComponent(fileURL.lastPathComponent)
            try fileManager.moveItem(at: fileURL, to: destination)
        }

        Logger.shared.warning("Store archived to \(archiveDirectory.path)", category: .database)
        return archiveDirectory
    }
}
