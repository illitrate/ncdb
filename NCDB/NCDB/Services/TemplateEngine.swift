//
//  TemplateEngine.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import Foundation

/// Simple template engine for generating HTML from data
@MainActor
final class TemplateEngine {
    static let shared = TemplateEngine()

    private init() {}

    // MARK: - Template Rendering

    /// Render a template with provided data
    func render(template: String, data: [String: Any]) -> String {
        var output = template

        // Replace simple variables {{variable}}
        for (key, value) in data {
            let placeholder = "{{\(key)}}"
            output = output.replacingOccurrences(of: placeholder, with: "\(value)")
        }

        // Handle loops {{#each array}}...{{/each}}
        output = processLoops(in: output, data: data)

        // Handle conditionals {{#if condition}}...{{/if}}
        output = processConditionals(in: output, data: data)

        return output
    }

    // MARK: - Loop Processing

    private func processLoops(in template: String, data: [String: Any]) -> String {
        var output = template
        let loopPattern = "\\{\\{#each (\\w+)\\}\\}([\\s\\S]*?)\\{\\{/each\\}\\}"

        guard let regex = try? NSRegularExpression(pattern: loopPattern, options: []) else {
            return output
        }

        let matches = regex.matches(in: output, options: [], range: NSRange(output.startIndex..., in: output))

        for match in matches.reversed() {
            guard match.numberOfRanges == 3,
                  let arrayNameRange = Range(match.range(at: 1), in: output),
                  let templateRange = Range(match.range(at: 2), in: output),
                  let fullRange = Range(match.range(at: 0), in: output) else {
                continue
            }

            let arrayName = String(output[arrayNameRange])
            let itemTemplate = String(output[templateRange])

            if let array = data[arrayName] as? [[String: Any]] {
                let renderedItems = array.map { itemData in
                    render(template: itemTemplate, data: itemData)
                }.joined()

                output.replaceSubrange(fullRange, with: renderedItems)
            }
        }

        return output
    }

    // MARK: - Conditional Processing

    private func processConditionals(in template: String, data: [String: Any]) -> String {
        var output = template
        let conditionalPattern = "\\{\\{#if (\\w+)\\}\\}([\\s\\S]*?)\\{\\{/if\\}\\}"

        guard let regex = try? NSRegularExpression(pattern: conditionalPattern, options: []) else {
            return output
        }

        let matches = regex.matches(in: output, options: [], range: NSRange(output.startIndex..., in: output))

        for match in matches.reversed() {
            guard match.numberOfRanges == 3,
                  let conditionNameRange = Range(match.range(at: 1), in: output),
                  let contentRange = Range(match.range(at: 2), in: output),
                  let fullRange = Range(match.range(at: 0), in: output) else {
                continue
            }

            let conditionName = String(output[conditionNameRange])
            let content = String(output[contentRange])

            if let condition = data[conditionName] as? Bool, condition {
                output.replaceSubrange(fullRange, with: content)
            } else {
                output.replaceSubrange(fullRange, with: "")
            }
        }

        return output
    }

    // MARK: - Built-in Templates

    /// Get default website template
    func getDefaultTemplate() -> String {
        """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>{{userName}}'s Nicolas Cage Movie Collection</title>
            <style>
                :root {
                    --cage-gold: #D4AF37;
                    --bg-dark: #0A0A0A;
                    --bg-card: #1A1A1A;
                    --text-primary: #FFFFFF;
                    --text-secondary: #B0B0B0;
                }

                * {
                    margin: 0;
                    padding: 0;
                    box-sizing: border-box;
                }

                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
                    background: var(--bg-dark);
                    color: var(--text-primary);
                    line-height: 1.6;
                }

                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    padding: 20px;
                }

                header {
                    text-align: center;
                    padding: 60px 20px;
                    background: linear-gradient(135deg, var(--bg-card), var(--bg-dark));
                }

                h1 {
                    font-size: 3em;
                    margin-bottom: 10px;
                    color: var(--cage-gold);
                }

                .subtitle {
                    font-size: 1.2em;
                    color: var(--text-secondary);
                }

                .stats {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 20px;
                    margin: 40px 0;
                }

                .stat-card {
                    background: var(--bg-card);
                    padding: 30px;
                    border-radius: 12px;
                    text-align: center;
                    border: 1px solid rgba(212, 175, 55, 0.1);
                }

                .stat-value {
                    font-size: 2.5em;
                    font-weight: bold;
                    color: var(--cage-gold);
                }

                .stat-label {
                    color: var(--text-secondary);
                    text-transform: uppercase;
                    font-size: 0.9em;
                    letter-spacing: 1px;
                    margin-top: 10px;
                }

                .section {
                    margin: 60px 0;
                }

                .section-title {
                    font-size: 2em;
                    margin-bottom: 30px;
                    color: var(--cage-gold);
                    border-bottom: 2px solid var(--cage-gold);
                    padding-bottom: 10px;
                }

                .movie-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
                    gap: 30px;
                }

                .movie-card {
                    background: var(--bg-card);
                    border-radius: 12px;
                    overflow: hidden;
                    transition: transform 0.3s ease;
                    border: 1px solid rgba(212, 175, 55, 0.1);
                }

                .movie-card:hover {
                    transform: translateY(-5px);
                    border-color: var(--cage-gold);
                }

                .movie-poster {
                    width: 100%;
                    aspect-ratio: 2/3;
                    object-fit: cover;
                    background: var(--bg-dark);
                }

                .movie-info {
                    padding: 15px;
                }

                .movie-title {
                    font-size: 1.1em;
                    margin-bottom: 5px;
                    font-weight: 600;
                }

                .movie-year {
                    color: var(--text-secondary);
                    font-size: 0.9em;
                }

                .movie-rating {
                    color: var(--cage-gold);
                    margin-top: 8px;
                    font-size: 0.9em;
                }

                .ranking {
                    background: var(--cage-gold);
                    color: var(--bg-dark);
                    padding: 8px 12px;
                    border-radius: 50%;
                    font-weight: bold;
                    display: inline-block;
                    margin-bottom: 10px;
                }

                footer {
                    text-align: center;
                    padding: 40px 20px;
                    color: var(--text-secondary);
                    border-top: 1px solid var(--bg-card);
                    margin-top: 60px;
                }

                .footer-note {
                    font-size: 0.9em;
                }

                @media (max-width: 768px) {
                    h1 { font-size: 2em; }
                    .movie-grid { grid-template-columns: repeat(auto-fill, minmax(150px, 1fr)); }
                }
            </style>
        </head>
        <body>
            <header>
                <h1>🎬 {{userName}}'s Nicolas Cage Collection</h1>
                <p class="subtitle">A dedicated tracker of the One True God's filmography</p>
            </header>

            <div class="container">
                <!-- Stats Section -->
                <div class="stats">
                    <div class="stat-card">
                        <div class="stat-value">{{watchedCount}}</div>
                        <div class="stat-label">Movies Watched</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">{{completionPercentage}}%</div>
                        <div class="stat-label">Completion</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">{{averageRating}}</div>
                        <div class="stat-label">Average Rating</div>
                    </div>
                    <div class="stat-card">
                        <div class="stat-value">{{totalRuntime}}</div>
                        <div class="stat-label">Total Runtime</div>
                    </div>
                </div>

                <!-- Top Rankings Section -->
                {{#if hasRankings}}
                <section class="section">
                    <h2 class="section-title">🏆 My Top Rankings</h2>
                    <div class="movie-grid">
                        {{#each rankedMovies}}
                        <div class="movie-card">
                            <span class="ranking">{{rank}}</span>
                            <img src="{{posterURL}}" alt="{{title}}" class="movie-poster" onerror="this.style.display='none'">
                            <div class="movie-info">
                                <div class="movie-title">{{title}}</div>
                                <div class="movie-year">{{year}}</div>
                                {{#if rating}}
                                <div class="movie-rating">⭐ {{rating}}/5</div>
                                {{/if}}
                            </div>
                        </div>
                        {{/each}}
                    </div>
                </section>
                {{/if}}

                <!-- All Watched Movies -->
                <section class="section">
                    <h2 class="section-title">📽️ Movies I've Watched</h2>
                    <div class="movie-grid">
                        {{#each watchedMovies}}
                        <div class="movie-card">
                            <img src="{{posterURL}}" alt="{{title}}" class="movie-poster" onerror="this.style.display='none'">
                            <div class="movie-info">
                                <div class="movie-title">{{title}}</div>
                                <div class="movie-year">{{year}}</div>
                                {{#if rating}}
                                <div class="movie-rating">⭐ {{rating}}/5</div>
                                {{/if}}
                            </div>
                        </div>
                        {{/each}}
                    </div>
                </section>
            </div>

            <footer>
                <p class="footer-note">
                    Generated by NCDB - Nicolas Cage Database<br>
                    Last updated: {{lastUpdated}}<br>
                    © {{currentYear}} {{userName}}
                </p>
            </footer>
        </body>
        </html>
        """
    }
}
