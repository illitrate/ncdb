//
//  NewsArticleDetailView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI
import SafariServices

/// Article detail view with web content
struct NewsArticleDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let article: NewsArticle

    @State private var showingSafari = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Header image
                    if let imageURL = article.imageURL, let url = URL(string: imageURL) {
                        CachedAsyncImage(url: url, placeholder: {
                            Rectangle()
                                .fill(Color(hex: "1A1A1A"))
                        }, content: { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        })
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium))
                    }

                    // Metadata
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        HStack {
                            Text(article.source)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(Color.cageGold)

                            Spacer()

                            Text(article.publishedDate, style: .relative)
                                .font(.caption)
                                .foregroundStyle(Color.secondaryText)
                        }

                        Text(article.publishedDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(Color.secondaryText)
                    }

                    Divider()

                    // Title
                    Text(article.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.primaryText)

                    // Summary (hide for Google News as it's just HTML links)
                    if let summary = article.summary, !summary.isEmpty, article.source != "Google News" {
                        Text(summary)
                            .font(.body)
                            .foregroundStyle(Color.primaryText)
                            .lineSpacing(4)
                    }

                    // Info message for Google News articles
                    if article.source == "Google News" {
                        Text("Google News provides links to articles from various sources. Tap 'Read Full Article' below to view the complete story.")
                            .font(.subheadline)
                            .foregroundStyle(Color.secondaryText)
                            .padding(.vertical, Spacing.sm)
                            .padding(.horizontal, Spacing.md)
                            .background(Color(hex: "1A1A1A"))
                            .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusSmall))
                    }

                    // Read full article button
                    GlassButton(title: "Read Full Article", style: .primary) {
                        openArticle()
                    }

                    Spacer()
                }
                .padding()
            }
            .background(Color.black)
            .navigationTitle("Article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        shareArticle()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showingSafari) {
                SafariView(url: URL(string: article.url)!)
            }
        }
    }

    // MARK: - Actions

    private func openArticle() {
        if let url = URL(string: article.url) {
            showingSafari = true
        }
    }

    private func shareArticle() {
        guard let url = URL(string: article.url) else { return }

        let activityVC = UIActivityViewController(
            activityItems: [article.title, url],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Safari View

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    NewsArticleDetailView(
        article: NewsArticle(
            url: "https://example.com/article",
            title: "Nicolas Cage to Star in New Action Thriller",
            summary: "The legendary actor will play a detective in the upcoming film, set to begin production next month. This marks his return to action cinema after his acclaimed dramatic performances.",
            source: "Variety",
            publishedDate: Date().addingTimeInterval(-3600)
        )
    )
}
