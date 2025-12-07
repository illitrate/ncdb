//
//  NewsRow.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// News article row component
struct NewsRow: View {
    let article: NewsArticle
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: Spacing.md) {
                // Thumbnail (if available)
                if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                    CachedAsyncImage(url: url, placeholder: {
                        Rectangle()
                            .fill(Color(hex: "1A1A1A"))
                    }, content: { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    })
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusSmall))
                }

                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Title
                    Text(article.title)
                        .font(.headline)
                        .foregroundStyle(Color.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    // Summary
                    if let summary = article.summary, !summary.isEmpty {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(Color.secondaryText)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    // Metadata
                    HStack(spacing: Spacing.sm) {
                        // Source
                        Text(article.source)
                            .font(.caption)
                            .foregroundStyle(Color.cageGold)

                        Text("•")
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)

                        // Time
                        Text(timeAgoString(from: article.publishedDate))
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)

                        // Unread indicator
                        if !article.isRead {
                            Spacer()

                            Circle()
                                .fill(Color.cageGold)
                                .frame(width: 8, height: 8)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium)
                    .fill(Color(hex: "1A1A1A"))
                    .opacity(article.isRead ? 0.5 : 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Time Formatting

    private func timeAgoString(from date: Date) -> String {
        let now = Date()
        let interval = now.timeIntervalSince(date)

        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else if interval < 604800 {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

#Preview {
    NewsRow(
        article: NewsArticle(
            url: "https://example.com/article",
            title: "Nicolas Cage to Star in New Action Thriller",
            summary: "The legendary actor will play a detective in the upcoming film, set to begin production next month.",
            source: "Variety",
            publishedDate: Date().addingTimeInterval(-3600)
        ),
        onTap: {}
    )
    .padding()
    .background(Color.black)
}
