//
//  StatsView.swift
//  Breaks
//
//  Statistics page: streak hero, heatmap, weekly review, session history.
//

import SwiftUI

// MARK: - Streak Hero Card

struct StreakHeroCard: View {
    let snapshot: StreakSnapshot
    let accentColor: Color

    private var pauseLabel: String {
        if snapshot.pauseDayBudget == 0 {
            return "No rest days"
        }
        return "\(snapshot.pauseDaysUsedThisWeek)/\(snapshot.pauseDayBudget) rest days used"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Streak")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(snapshot.streak)")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(accentColor)
                    Text(snapshot.streak == 1 ? "day" : "days")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(pauseLabel)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(accentColor.opacity(0.8))
                Text("Decay, not reset")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .glassCard(tint: accentColor, cornerRadius: 10)
    }
}

// MARK: - Streak Heatmap

struct StreakHeatmap: View {
    let snapshot: StreakSnapshot
    let accentColor: Color

    @State private var appeared = false
    private let weeks = 12
    private let cellSize: CGFloat = 12
    private let cellGap: CGFloat = 3

    private var grid: [[Date]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysFromStart = (weekday - calendar.firstWeekday + 7) % 7
        guard let startOfThisWeek = calendar.date(byAdding: .day, value: -daysFromStart, to: today),
              let firstShownWeek = calendar.date(byAdding: .day, value: -7 * (weeks - 1), to: startOfThisWeek) else {
            return []
        }
        var columns: [[Date]] = []
        for w in 0..<weeks {
            guard let weekStart = calendar.date(byAdding: .day, value: w * 7, to: firstShownWeek) else { continue }
            var col: [Date] = []
            for d in 0..<7 {
                if let day = calendar.date(byAdding: .day, value: d, to: weekStart) {
                    col.append(calendar.startOfDay(for: day))
                }
            }
            columns.append(col)
        }
        return columns
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Last 12 weeks")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                LegendRow(accentColor: accentColor)
            }
            HStack(alignment: .top, spacing: cellGap) {
                ForEach(Array(grid.enumerated()), id: \.offset) { idx, column in
                    VStack(spacing: cellGap) {
                        ForEach(column, id: \.self) { day in
                            cell(for: day)
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .scaleEffect(appeared ? 1 : 0.85, anchor: .bottom)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.85)
                            .delay(Double(idx) * 0.022),
                        value: appeared
                    )
                }
            }
        }
        .onAppear {
            DispatchQueue.main.async { appeared = true }
        }
    }

    @ViewBuilder
    private func cell(for day: Date) -> some View {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let status = snapshot.statusByDay[day]
        let isFuture = day > today

        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
            .fill(fillColor(for: status, isFuture: isFuture))
            .overlay(
                RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                    .strokeBorder(borderColor(for: status), style: StrokeStyle(lineWidth: 1, dash: dashPattern(for: status)))
            )
            .frame(width: cellSize, height: cellSize)
            .help(tooltip(for: day, status: status))
    }

    private func fillColor(for status: DayStatus?, isFuture: Bool) -> Color {
        if isFuture { return Color.secondary.opacity(0.04) }
        switch status {
        case .completed(let n):
            let intensity = min(1.0, 0.35 + Double(n) * 0.15)
            return accentColor.opacity(intensity)
        case .pause:
            return accentColor.opacity(0.12)
        case .missed:
            return Color.secondary.opacity(0.10)
        case .today:
            return Color.secondary.opacity(0.10)
        case .upcoming, .none:
            return Color.secondary.opacity(0.08)
        }
    }

    private func borderColor(for status: DayStatus?) -> Color {
        switch status {
        case .pause: return accentColor.opacity(0.55)
        case .today: return accentColor.opacity(0.7)
        default: return .clear
        }
    }

    private func dashPattern(for status: DayStatus?) -> [CGFloat] {
        switch status {
        case .pause: return [2, 1.5]
        default: return []
        }
    }

    private func tooltip(for day: Date, status: DayStatus?) -> String {
        let date = day.formatted(date: .abbreviated, time: .omitted)
        switch status {
        case .completed(let n): return "\(date): \(n) block\(n == 1 ? "" : "s")"
        case .pause: return "\(date): rest day (no decay)"
        case .missed: return "\(date): missed (-1)"
        case .today: return "\(date): today"
        case .upcoming, .none: return date
        }
    }
}

// MARK: - Legend Row

struct LegendRow: View {
    let accentColor: Color

    var body: some View {
        HStack(spacing: 8) {
            legend(color: accentColor.opacity(0.55), label: "Done")
            legend(color: accentColor.opacity(0.12), label: "Rest", dashed: true)
            legend(color: Color.secondary.opacity(0.10), label: "Miss")
        }
        .font(.system(size: 9))
        .foregroundStyle(.secondary)
    }

    private func legend(color: Color, label: String, dashed: Bool = false) -> some View {
        HStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .overlay(
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .strokeBorder(dashed ? accentColor.opacity(0.55) : .clear,
                                      style: StrokeStyle(lineWidth: 1, dash: dashed ? [2, 1.5] : []))
                )
                .frame(width: 9, height: 9)
            Text(label)
        }
    }
}

// MARK: - Statistics View

struct StatsView: View {
    @ObservedObject var history: SessionHistory
    @ObservedObject var journal: FocusJournal
    @ObservedObject var settings: TimerSettings
    @ObservedObject var projects: FocusProjectLibrary
    @Binding var showing: Bool
    private var snapshot: StreakSnapshot {
        history.streakSnapshot(pauseDayBudget: settings.pauseDaysPerWeek)
    }

    var body: some View {
        let snap = snapshot
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Text("Statistics").font(.headline)
                    HStack {
                        Button { showing = false } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.escape, modifiers: [])
                        Spacer()
                    }
                }
                Divider()

                StreakHeroCard(snapshot: snap, accentColor: settings.accentColor)

                StreakHeatmap(snapshot: snap, accentColor: settings.accentColor)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    StatRow(title: "Today", value: "\(history.totalToday())")
                    StatRow(title: "Focused today", value: "\(journal.focusedMinutesToday())m")
                    StatRow(title: "This week", value: "\(history.totalThisWeek())")
                    StatRow(title: "Focus days", value: "\(journal.focusDaysThisWeek())")
                    StatRow(title: "All time", value: "\(history.totalAllTime())")
                }

                Divider()
                WeeklyReviewView(history: history, journal: journal, projects: projects)
                Divider()
                Text("Recent days")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(history.records.prefix(7), id: \.date) { record in
                    HStack {
                        Text(record.date.formatted(date: .abbreviated, time: .omitted))
                        Spacer()
                        Text("\(record.completedSessions)")
                            .monospacedDigit()
                    }
                    .font(.caption)
                }
                if history.records.isEmpty {
                    Text("No sessions yet. Start your first block.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
        }
        .frame(height: 520)
    }

    private struct StatRow: View {
        let title: String
        let value: String
        var body: some View {
            HStack {
                Text(title)
                Spacer()
                Text(value).bold()
            }
            .font(.body)
        }
    }
}

// MARK: - Weekly Review

struct WeeklyReviewView: View {
    @ObservedObject var history: SessionHistory
    @ObservedObject var journal: FocusJournal
    @ObservedObject var projects: FocusProjectLibrary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Weekly review")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            ForEach(journal.weeklyReviewDays()) { day in
                HStack(spacing: 8) {
                    Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 30, alignment: .leading)
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.secondary.opacity(0.14))
                            Capsule()
                                .fill(Color.accentColor.opacity(0.75))
                                .frame(width: proxy.size.width * barProgress(for: day))
                        }
                    }
                    .frame(height: 7)
                    Text("\(history.completions(on: day.date))")
                        .font(.caption2)
                        .monospacedDigit()
                        .frame(width: 18, alignment: .trailing)
                }
            }
            let labels = journal.topLabelsThisWeek()
            if !labels.isEmpty {
                HStack(spacing: 5) {
                    ForEach(labels, id: \.label) { item in
                        Text("\(item.label) \(item.count)")
                            .font(.caption2)
                            .lineLimit(1)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Color.secondary.opacity(0.12))
                            )
                    }
                }
            }
            let breakdown = journal.weeklyProjectBreakdown()
            if !breakdown.isEmpty {
                Text("By project")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.top, 2)
                ForEach(breakdown) { item in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(projects.project(for: item.projectID)?.color ?? Color.secondary.opacity(0.4))
                            .frame(width: 7, height: 7)
                        Text(item.projectName)
                            .font(.caption2)
                            .lineLimit(1)
                        Spacer()
                        Text("\(item.minutes)m · \(item.blocks)")
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private func barProgress(for day: WeeklyFocusDay) -> Double {
        let maxBlocks = max(1, journal.weeklyReviewDays().map(\.blocks).max() ?? 1)
        return min(1, Double(day.blocks) / Double(maxBlocks))
    }
}
