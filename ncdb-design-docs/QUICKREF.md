# Quick Reference

## Creating a new glass card:
\`\`\`swift
GlassCard {
    VStack {
        Text("Content")
    }
}
\`\`\`

## Fetching TMDb data:
\`\`\`swift
let service = TMDbService(apiKey: apiKey)
let movies = try await service.fetchNicolasCageMovies()
\`\`\`
