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
    @StateObject private var ai = WeeklyAIReview()
    @StateObject private var chat = JournalAIChat()
    @State private var expandedKey: String?
    @State private var question: String = ""
    @State private var showChat: Bool = false

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
            AIWeeklySummaryView(ai: ai) {
                journal.weeklyPromptContext()
            }

            AIJournalChatView(
                chat: chat,
                question: $question,
                expanded: $showChat,
                contextBuilder: { journal.weeklyPromptContext() }
            )

            let breakdown = journal.weeklyProjectBreakdown()
            if !breakdown.isEmpty {
                Text("By project")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .padding(.top, 2)
                ForEach(breakdown) { item in
                    let key = item.projectID?.uuidString ?? "__noproject__"
                    let isExpanded = expandedKey == key
                    VStack(alignment: .leading, spacing: 4) {
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                expandedKey = isExpanded ? nil : key
                            }
                        } label: {
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
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if isExpanded {
                            ProjectDetailCard(stats: journal.detailStats(for: item.projectID),
                                              color: projects.project(for: item.projectID)?.color ?? Color.secondary)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
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

// MARK: - Project Detail Card

struct ProjectDetailCard: View {
    let stats: FocusJournal.ProjectDetailStats
    let color: Color

    private var maxMinutes: Int {
        max(1, stats.dailyMinutes.map(\.minutes).max() ?? 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                statTile("Week", value: "\(stats.weekMinutes)m")
                statTile("Month", value: "\(stats.monthMinutes)m")
                statTile("All time", value: "\(stats.allTimeMinutes)m")
            }
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(stats.dailyMinutes) { day in
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(color.opacity(day.minutes == 0 ? 0.15 : 0.7))
                            .frame(height: max(3, CGFloat(day.minutes) / CGFloat(maxMinutes) * 32))
                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.system(size: 8))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 44)
            HStack(spacing: 10) {
                outcomeChip(label: "Good", count: stats.goodCount, tint: .green)
                outcomeChip(label: "Messy", count: stats.messyCount, tint: .orange)
                outcomeChip(label: "Skipped", count: stats.skippedCount, tint: .secondary)
                Spacer()
                Text("\(stats.totalBlocks) blocks")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(color.opacity(0.06))
        )
    }

    private func statTile(_ label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func outcomeChip(label: String, count: Int, tint: Color) -> some View {
        HStack(spacing: 3) {
            Circle().fill(tint).frame(width: 5, height: 5)
            Text("\(label) \(count)")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - AI Weekly Summary

struct AIWeeklySummaryView: View {
    @ObservedObject var ai: WeeklyAIReview
    let promptBuilder: () -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("Breaks AI")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Spacer()
                if case .loaded = ai.state {
                    Button {
                        ai.regenerate(prompt: promptBuilder())
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.caption2)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .help("Regenerate summary")
                }
            }
            content
        }
        .padding(.top, 6)
        .onAppear {
            ai.generateIfNeeded(prompt: promptBuilder)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch ai.state {
        case .idle:
            EmptyView()
        case .loading:
            HStack(spacing: 6) {
                ProgressView().controlSize(.small)
                Text("Reviewing your week…")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        case .loaded(let text, _):
            Text(text)
                .font(.caption)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        case .unsupportedOS:
            Text("Breaks AI needs macOS 26 or newer.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .modelUnavailable(let reason):
            Text(reason)
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .failed(let msg):
            HStack(spacing: 4) {
                Text("Couldn't generate: \(msg)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                Button("Retry") { ai.regenerate(prompt: promptBuilder()) }
                    .font(.caption2)
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
            }
        }
    }
}

// MARK: - AI Journal Chat

struct AIJournalChatView: View {
    @ObservedObject var chat: JournalAIChat
    @Binding var question: String
    @Binding var expanded: Bool
    let contextBuilder: () -> String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                    expanded.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.text.bubble.right")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Ask Breaks AI")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 6)
    }

    @ViewBuilder
    private var content: some View {
        switch chat.availability {
        case .available:
            VStack(alignment: .leading, spacing: 6) {
                if !chat.messages.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(chat.messages) { msg in
                            messageBubble(msg)
                        }
                        if let err = chat.error {
                            Text(err)
                                .font(.caption2)
                                .foregroundStyle(.red.opacity(0.8))
                        }
                    }
                }
                if chat.isThinking {
                    HStack(spacing: 6) {
                        ProgressView().controlSize(.small)
                        Text("Thinking…")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 6) {
                    TextField("e.g. when did I focus best?", text: $question)
                        .textFieldStyle(.roundedBorder)
                        .font(.caption)
                        .disabled(chat.isThinking)
                        .onSubmit(send)
                    Button(action: send) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .disabled(chat.isThinking || question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    if !chat.messages.isEmpty {
                        Button {
                            chat.clear()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
                if chat.messages.isEmpty {
                    suggestionChips
                }
            }
        case .unsupportedOS:
            Text("Breaks AI needs macOS 26 or newer.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .unavailable(let reason):
            Text(reason)
                .font(.caption2)
                .foregroundStyle(.secondary)
        case .checking:
            Text("Checking model availability…")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var suggestionChips: some View {
        let suggestions = [
            "When did I focus best?",
            "Which project took the most time?",
            "Where did I drift?"
        ]
        return HStack(spacing: 5) {
            ForEach(suggestions, id: \.self) { s in
                Button {
                    question = s
                    send()
                } label: {
                    Text(s)
                        .font(.system(size: 10))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.secondary.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func messageBubble(_ msg: JournalAIChat.Message) -> some View {
        HStack {
            if msg.role == .user { Spacer(minLength: 24) }
            Text(msg.text)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(msg.role == .user ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.10))
                )
                .fixedSize(horizontal: false, vertical: true)
            if msg.role == .assistant { Spacer(minLength: 24) }
        }
    }

    private func send() {
        let trimmed = question.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        question = ""
        chat.ask(trimmed, context: contextBuilder())
    }
}
