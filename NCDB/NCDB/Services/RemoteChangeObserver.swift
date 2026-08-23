//
//  RemoteChangeObserver.swift
//  NCDB
//
//  Reacts to CloudKit merges landing in the local store.
//

import Foundation
import CoreData
import SwiftData

/// Listens for remote store changes and repairs anything a per-property merge
/// can leave inconsistent.
///
/// SwiftData is built on Core Data, and CloudKit imports still post
/// `NSPersistentStoreRemoteChange`. That notification is the only signal the
/// app gets that another device's edits have arrived.
@MainActor
final class RemoteChangeObserver {

    private var observer: NSObjectProtocol?
    private var pendingWork: Task<Void, Never>?

    func start(context: ModelContext) {
        guard observer == nil else { return }

        // Note the closure captures only `self` — a @MainActor class, and so
        // Sendable. The context is fetched on the main actor when the work
        // actually runs, because ModelContext isn't Sendable and must not
        // cross the boundary.
        observer = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            Task { @MainActor in
                self?.scheduleReconciliation()
            }
        }

        Logger.shared.info("Watching for remote store changes", category: .database)
    }

    /// Deliberately no `deinit`: this object is owned by the `App` and lives for
    /// the process, and a nonisolated `deinit` can't touch main-actor state
    /// under Swift 6. `stop()` exists for tests.
    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
        pendingWork?.cancel()
        pendingWork = nil
    }

    /// A sync pulls many records in quick succession, so coalesce rather than
    /// reconciling once per incoming record.
    private func scheduleReconciliation() {
        pendingWork?.cancel()
        pendingWork = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }

            guard let context = DataManager.shared.modelContext else { return }

            if RankingReconciler.needsReconciliation(in: context) {
                RankingReconciler.reconcile(in: context)
            }

            // Widgets show ranks and counts, so refresh them too.
            await WidgetDataService.shared.refreshFromStore()

            Logger.shared.debug("Handled remote store change", category: .database)
        }
    }
}
