// NCDB Stats View
// Statistics dashboard with charts and insights

import SwiftUI
import SwiftData
import Charts

// MARK: - Stats View

/// Statistics dashboard displaying viewing analytics and insights
///
/// Sections:
/// - Overview stats grid
/// - Genre breakdown chart
/// - Decade distribution chart
/// - Rating distribution
/// - Insights and fun facts
/// - Achievement progress
struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = StatsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Spacing.sectionSpacing) {
                    // Overview Stats
                    OverviewStatsGrid(stats: viewModel.overviewStats)

                    // Genre Chart
                    if !viewModel.genreData.isEmpty {
                        ChartSection(title: "Movies by Genre") {
                            GenreChart(data: viewModel.genreData)
                        }
                    }

                    // Decade Chart
                    if !viewModel.decadeData.isEmpty {
                        ChartSection(title: "Movies by Decade") {
                            DecadeChart(data: viewModel.decadeData)
                        }
                    }

                    // Rating Distribution
                    if !viewModel.ratingDistribution.isEmpty {
                        ChartSection(title: "Your Ratings") {
                            RatingDistributionChart(data: viewModel.ratingDistribution)
                        }
                    }

                    // Monthly Activity
                    if !viewModel.monthlyWatches.isEmpty {
                        ChartSection(title: "Watch Activity (Last 12 Months)") {
                            MonthlyActivityChart(data: viewModel.monthlyWatches)
                        }
                    }

                    // Insights
                    if !viewModel.insights.isEmpty {
                        InsightsSection(insights: viewModel.insights)
                    }

                    // Achievement Progress
                    if !viewModel.achievementProgress.isEmpty {
                        AchievementProgressSection(progress: viewModel.achievementProgress)
                    }

                    // Bottom padding
                    Spacer().frame(height: Spacing.huge)
                }
            }
            .background(Color.primaryBackground)
            .navigationTitle("Statistics")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingView(message: "Calculating stats...")
                }
            }
            .sheet(isPresented: $viewModel.showShareSheet) {
                ShareStatsSheet(viewModel: viewModel)
            }
        }
        .task {
            viewModel.configure(modelContext: modelContext)
            await viewModel.calculateStats()
        }
    }
}

// MARK: - Overview Stats Grid

struct OverviewStatsGrid: View {
    let stats: OverviewStats

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Spacing.md) {
            StatCard(
                title: "Watched",
                value: "\(stats.watchedCount)",
                icon: "checkmark.circle.fill",
                color: .green,
                subtitle: "of \(stats.totalMovies) movies"
            )

            StatCard(
                title: "Completion",
                value: stats.formattedCompletion,
                icon: "chart.pie.fill",
                color: .cageGold
            )

            StatCard(
                title: "Average Rating",
                value: stats.formattedAverageRating,
                icon: "star.fill",
                color: .cageGold,
                subtitle: "out of 5.0"
            )

            StatCard(
                title: "Total Time",
                value: stats.formattedRuntime,
                icon: "clock.fill",
                color: .blue,
                subtitle: "with Nicolas Cage"
            )

            StatCard(
                title: "Favorites",
                value: "\(stats.favoriteCount)",
                icon: "heart.fill",
                color: .red
            )

            StatCard(
                title: "Ranked",
                value: "\(stats.rankedCount)",
                icon: "trophy.fill",
                color: .cageGold
            )
        }
        .padding(.horizontal, Spacing.screenPadding)
    }
}

// MARK: - Chart Section Container

struct ChartSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: title)

            GlassCard(cornerRadius: Sizes.cornerRadiusLarge, padding: Spacing.md) {
                content
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }
}

// MARK: - Genre Chart

struct GenreChart: View {
    let data: [ChartDataPoint]

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Count", point.value),
                y: .value("Genre", point.label)
            )
            .foregroundStyle(point.color)
            .cornerRadius(4)
        }
        .chartXAxis {
            AxisMarks(position: .bottom)
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisValueLabel()
            }
        }
        .frame(height: CGFloat(data.count) * 35)
    }
}

// MARK: - Decade Chart

struct DecadeChart: View {
    let data: [ChartDataPoint]

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Decade", point.label),
                y: .value("Count", point.value)
            )
            .foregroundStyle(Color.cageGold.gradient)
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 200)
    }
}

// MARK: - Rating Distribution Chart

struct RatingDistributionChart: View {
    let data: [ChartDataPoint]

    var body: some View {
        Chart(data) { point in
            BarMark(
                x: .value("Rating", point.label),
                y: .value("Count", point.value)
            )
            .foregroundStyle(point.color.gradient)
            .cornerRadius(4)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 150)
    }
}

// MARK: - Monthly Activity Chart

struct MonthlyActivityChart: View {
    let data: [ChartDataPoint]

    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Month", point.label),
                y: .value("Count", point.value)
            )
            .foregroundStyle(Color.cageGold)
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Month", point.label),
                y: .value("Count", point.value)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.cageGold.opacity(0.3), Color.cageGold.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            PointMark(
                x: .value("Month", point.label),
                y: .value("Count", point.value)
            )
            .foregroundStyle(Color.cageGold)
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .frame(height: 150)
    }
}

// MARK: - Insights Section

struct InsightsSection: View {
    let insights: [StatInsight]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Insights")

            VStack(spacing: Spacing.sm) {
                ForEach(insights) { insight in
                    InsightRow(insight: insight)
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }
}

struct InsightRow: View {
    let insight: StatInsight

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: insight.icon)
                .font(.title2)
                .foregroundStyle(Color.cageGold)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(insight.title)
                    .font(Typography.caption1)
                    .foregroundStyle(Color.secondaryText)

                Text(insight.value)
                    .font(Typography.title3)
                    .foregroundStyle(Color.primaryText)

                Text(insight.detail)
                    .font(Typography.caption2)
                    .foregroundStyle(Color.tertiaryText)
            }

            Spacer()
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Achievement Progress Section

struct AchievementProgressSection: View {
    let progress: [AchievementProgress]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Achievement Progress")

            VStack(spacing: Spacing.sm) {
                ForEach(progress) { item in
                    AchievementProgressRow(progress: item)
                }
            }
            .padding(.horizontal, Spacing.screenPadding)
        }
    }
}

struct AchievementProgressRow: View {
    let progress: AchievementProgress

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Completion indicator
            ZStack {
                Circle()
                    .stroke(Color.glassLight, lineWidth: 3)
                    .frame(width: 44, height: 44)

                Circle()
                    .trim(from: 0, to: progress.percentage)
                    .stroke(Color.cageGold, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                if progress.isComplete {
                    Image(systemName: "checkmark")
                        .font(.body.bold())
                        .foregroundStyle(Color.cageGold)
                }
            }

            VStack(alignment: .leading, spacing: Spacing.xxxs) {
                Text(progress.title)
                    .font(Typography.body)
                    .foregroundStyle(progress.isComplete ? Color.cageGold : Color.primaryText)

                Text(progress.formattedProgress)
                    .font(Typography.caption1)
                    .foregroundStyle(Color.secondaryText)
            }

            Spacer()

            Text("\(Int(progress.percentage * 100))%")
                .font(Typography.caption1Bold)
                .foregroundStyle(Color.cageGold)
        }
        .padding(Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium)
                .fill(.ultraThinMaterial)
        )
    }
}

// MARK: - Share Stats Sheet

struct ShareStatsSheet: View {
    @Bindable var viewModel: StatsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: Spacing.lg) {
                // Preview
                ScrollView {
                    Text(viewModel.generateShareableStats())
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium))
                }

                // Share button
                ShareLink(
                    item: viewModel.generateShareableStats(),
                    subject: Text("My Nicolas Cage Stats"),
                    message: Text("Check out my stats!")
                ) {
                    Label("Share Stats", systemImage: "square.and.arrow.up")
                        .font(Typography.button)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cageGold)
                        .foregroundStyle(.black)
                        .clipShape(RoundedRectangle(cornerRadius: Sizes.cornerRadiusMedium))
                }
            }
            .padding()
            .navigationTitle("Share Stats")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    StatsView()
        .modelContainer(for: Production.self, inMemory: true)
}
