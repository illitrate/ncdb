// NCDB Database Recovery
// Shown when the persistent store cannot be opened. Replaces the old behaviour
// of silently deleting the user's library and starting fresh.

import SwiftUI

struct DatabaseRecoveryView: View {

    let error: Error
    let onRetry: () -> Void

    @State private var showingResetConfirmation = false
    @State private var archivePath: String?
    @State private var resetFailure: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {

                header

                if let archivePath {
                    archivedNotice(path: archivePath)
                } else {
                    explanation
                    actions
                }

                if let resetFailure {
                    Text(resetFailure)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                details
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.primaryBackground)
        .preferredColorScheme(.dark)
        .confirmationDialog(
            "Set your library aside?",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Set Aside and Start Fresh", role: .destructive) {
                archiveStore()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your existing library will be moved into a dated folder inside the app's storage rather than deleted, so it can still be recovered. NCDB will then start with an empty library.")
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.cageGold)

            Text("Your library couldn't be opened")
                .font(.title2.bold())
                .foregroundStyle(Color.primaryText)
        }
    }

    private var explanation: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("NCDB found your library but couldn't read it. Nothing has been changed or deleted.")
                .foregroundStyle(Color.primaryText)

            if NCDBModelContainer.storeExists {
                Text("Your library file is still on disk (\(NCDBModelContainer.storeSizeDescription)).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Text("Try again first — a failure here is often caused by the app being updated while it was still running. If it keeps failing, you can set the library aside and start fresh.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Button {
                onRetry()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.cageGold)

            Button(role: .destructive) {
                showingResetConfirmation = true
            } label: {
                Label("Set Library Aside…", systemImage: "archivebox")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
        }
    }

    private func archivedNotice(path: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Library set aside")
                .font(.headline)
                .foregroundStyle(Color.primaryText)

            Text("Your old library was moved to:")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Text(path)
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            Button {
                onRetry()
            } label: {
                Label("Continue", systemImage: "arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .tint(.cageGold)
            .padding(.top, Spacing.xs)
        }
    }

    private var details: some View {
        DisclosureGroup("Technical details") {
            Text(String(describing: error))
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Spacing.xs)
        }
        .tint(Color.cageGold)
        .font(.footnote)
    }

    // MARK: - Actions

    private func archiveStore() {
        do {
            let destination = try NCDBModelContainer.archiveStore()
            archivePath = destination.path
            resetFailure = nil
            HapticManager.shared.warning()
        } catch {
            resetFailure = "Couldn't set the library aside: \(error.localizedDescription)"
            HapticManager.shared.error()
        }
    }
}

#Preview {
    DatabaseRecoveryView(
        error: NSError(domain: "NCDB", code: 134110, userInfo: [NSLocalizedDescriptionKey: "The model configuration used to open the store is incompatible with the one used to create the store."]),
        onRetry: {}
    )
}
