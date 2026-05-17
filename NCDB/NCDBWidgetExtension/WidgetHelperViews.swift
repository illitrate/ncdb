//
//  WidgetHelperViews.swift
//  NCDBWidgetExtension
//
//  Created by Claude Code on 2025-12-25.
//

import SwiftUI
import WidgetKit

// MARK: - Shared Background Views

struct PosterBackgroundView: View {
    let posterPath: String

    var body: some View {
        if let cachedImage = WidgetDataService.loadSharedPosterImage(posterPath: posterPath) {
            Image(uiImage: cachedImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .blur(radius: 4)
                .overlay(.black.opacity(0.6))
        } else {
            GradientBackgroundView()
        }
    }
}

struct GradientBackgroundView: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.15, green: 0.1, blue: 0.2)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
