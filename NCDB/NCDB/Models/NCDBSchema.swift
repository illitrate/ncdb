// NCDB Schema Versioning
// Declares the persisted schema, how it migrates, and how the store is opened.
//
// The rule this file exists to enforce: NCDB never deletes a user's library
// without being asked to. A store that fails to open is preserved and moved
// aside, never removed.

import Foundation
import SwiftData

// MARK: - Versioned Schema

/// The CloudKit-compatible schema.
///
/// v1 (the pre-2.1 shape) never shipped to anyone, so there is no migration
/// stage from it — an older store simply fails to open and the recovery screen
/// offers to set it aside. Once v2 *has* shipped, add `NCDBSchemaV3` alongside
/// this and append a `MigrationStage` rather than editing it in place.
///
/// CloudKit's constraints are what shaped this: no unique attributes, every
/// non-optional property carries a default, and every relationship is optional
/// with an explicit inverse.
enum NCDBSchemaV2: VersionedSchema {
    static var versionIdentifier: Schema.Version { Schema.Version(2, 0, 0) }

    static var models: [any PersistentModel.Type] {
        syncedModels + localModels
    }

    /// The user's library. Small, precious, and worth syncing.
    static var syncedModels: [any PersistentModel.Type] {
        [
            Production.self,
            CastMember.self,
            WatchEvent.self,
            ExternalRating.self,
            CustomTag.self,
            Achievement.self,
            UserPreferences.self,
            ExportTemplate.self
        ]
    }

    /// Re-fetchable cache. Deliberately not synced — it churns daily, caps at
    /// 100 rows, and would cost CloudKit quota for no benefit.
    static var localModels: [any PersistentModel.Type] {
        [
            NewsArticle.self
        ]
    }
}

// MARK: - Migration Plan

enum NCDBMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [NCDBSchemaV2.self]
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
        Schema(versionedSchema: NCDBSchemaV2.self)
    }

    // MARK: Configuration

    /// Whether the library syncs through CloudKit.
    ///
    /// `ModelConfiguration`'s `cloudKitDatabase` parameter defaults to
    /// `.automatic`, which enables sync the moment the app carries the
    /// entitlement — with no code change at all. Keeping it explicit means
    /// turning sync on stays a decision rather than a side effect of ticking a
    /// checkbox in Xcode.
    static let cloudKitSyncEnabled = true

    /// The CloudKit container backing the synced store.
    static let cloudKitContainerIdentifier = "iCloud.illitrate-Publicashions.NCDB"

    /// The user's library — synced.
    static func libraryConfiguration(inMemory: Bool = false) -> ModelConfiguration {
        ModelConfiguration(
            "Library",
            schema: Schema(NCDBSchemaV2.syncedModels, version: NCDBSchemaV2.versionIdentifier),
            isStoredInMemoryOnly: inMemory,
            allowsSave: true,
            cloudKitDatabase: cloudKitSyncEnabled && !inMemory
                ? .private(cloudKitContainerIdentifier)
                : .none
        )
    }

    /// The news cache — local only.
    static func newsConfiguration(inMemory: Bool = false) -> ModelConfiguration {
        ModelConfiguration(
            "News",
            schema: Schema(NCDBSchemaV2.localModels, version: NCDBSchemaV2.versionIdentifier),
            isStoredInMemoryOnly: inMemory,
            allowsSave: true,
            cloudKitDatabase: .none
        )
    }

    static func configuration(inMemory: Bool = false) -> ModelConfiguration {
        libraryConfiguration(inMemory: inMemory)
    }

    /// On-disk location of the library store, used by the recovery flow.
    static var storeURL: URL {
        libraryConfiguration().url
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

    /// Open both stores, running the migration plan.
    static func load(inMemory: Bool = false) throws -> ModelContainer {
        let container = try ModelContainer(
            for: schema,
            migrationPlan: NCDBMigrationPlan.self,
            configurations: [
                libraryConfiguration(inMemory: inMemory),
                newsConfiguration(inMemory: inMemory)
            ]
        )

        Logger.shared.info(
            "Model container opened (schema \(NCDBSchemaV2.versionIdentifier), CloudKit \(cloudKitSyncEnabled ? "on" : "off"))",
            category: .database
        )
        return container
    }

    /// A throwaway in-memory container, so the recovery UI and previews can run
    /// even when the real store is unreadable. Nothing written here is persisted.
    static func ephemeral() -> ModelContainer? {
        try? ModelContainer(
            for: schema,
            configurations: [
                libraryConfiguration(inMemory: true),
                newsConfiguration(inMemory: true)
            ]
        )
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
