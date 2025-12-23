//
//  DebugProductionCheck.swift
//  NCDB
//
//  Temporary debug helper
//

import SwiftUI
import SwiftData

struct DebugProductionCheck: View {
    @Query private var productions: [Production]

    private var ghostRiderMovies: [Production] {
        productions.filter { $0.title.localizedCaseInsensitiveContains("Ghost Rider") }
    }

    var body: some View {
        List {
            ForEach(ghostRiderMovies) { production in
                VStack(alignment: .leading, spacing: 8) {
                    Text(production.title)
                        .font(.headline)

                    Group {
                        Text("Character: \(production.characterName ?? "nil")")
                        Text("isNonActingAppearance: \(production.isNonActingAppearance.description)")
                        Text("productionType: \(production.productionType.rawValue)")
                        Text("manuallyIncluded: \(production.manuallyIncluded.description)")
                        Text("wouldBeFiltered: \(production.wouldBeFiltered.description)")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Ghost Rider Debug")
    }
}
