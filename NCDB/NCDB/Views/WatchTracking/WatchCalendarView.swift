//
//  WatchCalendarView.swift
//  NCDB
//
//  Created by Claude Code on 2025-12-07.
//

import SwiftUI

/// Calendar visualization with heat map of watch activity
struct WatchCalendarView: View {
    @State private var selectedYear: Int = Calendar.current.component(.year, from: Date())
    @State private var watchEventsByDate: [Date: Int] = [:]

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Year picker
                    HStack {
                        Button {
                            selectedYear -= 1
                        } label: {
                            Image(systemName: "chevron.left")
                        }

                        Text(String(selectedYear))
                            .font(.headline)
                            .frame(minWidth: 80)

                        Button {
                            selectedYear += 1
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(selectedYear >= calendar.component(.year, from: Date()))
                    }
                    .padding(Spacing.md)

                    // Calendar grid
                    ForEach(1...12, id: \.self) { month in
                        MonthView(
                            year: selectedYear,
                            month: month,
                            watchEventsByDate: watchEventsByDate
                        )
                    }

                    // Legend
                    HStack(spacing: Spacing.md) {
                        Text("Less")
                            .font(.caption)
                            .foregroundStyle(Color.tertiaryText)

                        ForEach(0...4, id: \.self) { intensity in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(heatMapColor(intensity: intensity))
                                .frame(width: 12, height: 12)
                        }

                        Text("More")
                            .font(.caption)
                            .foregroundStyle(Color.tertiaryText)
                    }
                    .padding(Spacing.md)
                }
            }
            .background(Color.primaryBackground)
            .navigationTitle("Watch Calendar")
            .onAppear {
                loadWatchEvents()
            }
        }
    }

    private func loadWatchEvents() {
        let eventsByMonth = WatchHistoryManager.shared.getWatchEventsByMonth()

        // Flatten to events by date
        var eventsByDate: [Date: Int] = [:]
        for (_, events) in eventsByMonth {
            for event in events {
                let date = calendar.startOfDay(for: event.watchedAt)
                eventsByDate[date, default: 0] += 1
            }
        }

        watchEventsByDate = eventsByDate
    }

    private func heatMapColor(intensity: Int) -> Color {
        switch intensity {
        case 0:
            return Color.gray.opacity(0.1)
        case 1:
            return Color.cageGold.opacity(0.3)
        case 2:
            return Color.cageGold.opacity(0.5)
        case 3:
            return Color.cageGold.opacity(0.7)
        default:
            return Color.cageGold
        }
    }
}

struct MonthView: View {
    let year: Int
    let month: Int
    let watchEventsByDate: [Date: Int]

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var monthName: String {
        let dateComponents = DateComponents(year: year, month: month)
        guard let date = calendar.date(from: dateComponents) else { return "" }
        return date.formatted(.dateTime.month(.wide))
    }

    private var daysInMonth: [Date?] {
        var days: [Date?] = []

        guard let firstDay = calendar.date(from: DateComponents(year: year, month: month, day: 1)),
              let range = calendar.range(of: .day, in: .month, for: firstDay) else {
            return days
        }

        let firstWeekday = calendar.component(.weekday, from: firstDay)
        let leadingEmptyDays = firstWeekday - calendar.firstWeekday
        if leadingEmptyDays > 0 {
            days.append(contentsOf: Array(repeating: nil, count: leadingEmptyDays))
        }

        for day in range {
            if let date = calendar.date(from: DateComponents(year: year, month: month, day: day)) {
                days.append(date)
            }
        }

        return days
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(monthName)
                .font(.caption.bold())
                .foregroundStyle(Color.primaryText)
                .padding(.horizontal, Spacing.sm)

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(daysInMonth.indices, id: \.self) { index in
                    if let date = daysInMonth[index] {
                        DayCell(date: date, watchCount: watchEventsByDate[calendar.startOfDay(for: date)] ?? 0)
                    } else {
                        Color.clear
                            .frame(height: 30)
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)
        }
    }
}

struct DayCell: View {
    let date: Date
    let watchCount: Int

    private var intensity: Int {
        min(watchCount, 4) // Cap at 4 for heat map
    }

    private var backgroundColor: Color {
        switch intensity {
        case 0:
            return Color.gray.opacity(0.1)
        case 1:
            return Color.cageGold.opacity(0.3)
        case 2:
            return Color.cageGold.opacity(0.5)
        case 3:
            return Color.cageGold.opacity(0.7)
        default:
            return Color.cageGold
        }
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(backgroundColor)
            .frame(height: 30)
            .overlay(
                Text(String(Calendar.current.component(.day, from: date)))
                    .font(.caption2)
                    .foregroundStyle(watchCount > 0 ? Color.white : Color.tertiaryText)
            )
    }
}
