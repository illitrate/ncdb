// DataSeedingView.swift
// NCDB - Initial Data Seeding
// Loads Nicolas Cage filmography from TMDb

import SwiftUI

struct DataSeedingView: View {
    let onComplete: () -> Void
    @StateObject private var viewModel = DataSeedingViewModel()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Animated Loading Icon
                ZStack {
                    Circle()
                        .stroke(Color(hex: "FFD700").opacity(0.3), lineWidth: 4)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .trim(from: 0, to: viewModel.progress)
                        .stroke(Color(hex: "FFD700"), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear, value: viewModel.progress)
                    
                    Image(systemName: "film")
                        .font(.system(size: 40))
                        .foregroundStyle(Color(hex: "FFD700"))
                }
                
                // Title & Progress
                VStack(spacing: 12) {
                    Text("Loading Your Collection")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("\(Int(viewModel.progress * 100))% Complete")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                // Status Updates
                VStack(alignment: .leading, spacing: 12) {
                    if viewModel.foundMoviesCount > 0 {
                        DataSeedingStatusRow(
                            text: "Found \(viewModel.foundMoviesCount) productions",
                            completed: true
                        )
                    }
                    if viewModel.isDownloadingPosters {
                        DataSeedingStatusRow(
                            text: "Downloading posters",
                            completed: false
                        )
                    }
                    if viewModel.isBuildingDatabase {
                        DataSeedingStatusRow(
                            text: "Building your vault",
                            completed: false
                        )
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            Task {
                await viewModel.seedInitialData()
                onComplete()
            }
        }
    }
}

struct DataSeedingStatusRow: View {
    let text: String
    let completed: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            if completed {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                ProgressView()
                    .tint(Color(hex: "FFD700"))
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}

@MainActor
class DataSeedingViewModel: ObservableObject {
    @Published var progress: Double = 0
    @Published var foundMoviesCount = 0
    @Published var isDownloadingPosters = false
    @Published var isBuildingDatabase = false
    
    func seedInitialData() async {
        // Step 1: Load bundled movies
        progress = 0.1
        try? await Task.sleep(for: .seconds(0.5))
        
        // Step 2: Fetch filmography from TMDb
        foundMoviesCount = await fetchFilmography()
        progress = 0.4
        
        // Step 3: Download posters
        isDownloadingPosters = true
        await downloadPosters()
        progress = 0.7
        
        // Step 4: Build database
        isBuildingDatabase = true
        await buildDatabase()
        progress = 1.0
        
        // Wait a moment before completing
        try? await Task.sleep(for: .seconds(0.5))
    }
    
    private func fetchFilmography() async -> Int {
        // TODO: Implement TMDb API call to get Nic Cage's filmography
        // This should use the TMDbService from 03-Services/
        try? await Task.sleep(for: .seconds(1.5))
        return 127 // Placeholder
    }
    
    private func downloadPosters() async {
        // TODO: Download poster images
        try? await Task.sleep(for: .seconds(1))
    }
    
    private func buildDatabase() async {
        // TODO: Save to SwiftData
        try? await Task.sleep(for: .seconds(1))
    }
}

#Preview {
    DataSeedingView(onComplete: {})
}
