import Foundation
import Combine

enum FocusOutcome: String, CaseIterable, Codable, Identifiable {
    case good = "Good"
    case messy = "Messy"
    case skipped = "Skipped"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .messy: return "scribble"
        case .skipped: return "xmark.circle"
        }
    }
}

struct FocusBlockLog: Codable, Identifiable {
    let id: UUID
    let date: Date
    let label: String
    let minutes: Int
    var outcome: FocusOutcome
    let projectID: UUID?
    let projectName: String?

    init(id: UUID = UUID(),
         date: Date,
         label: String,
         minutes: Int,
         outcome: FocusOutcome,
         projectID: UUID? = nil,
         projectName: String? = nil) {
        self.id = id
        self.date = date
        self.label = label
        self.minutes = minutes
        self.outcome = outcome
        self.projectID = projectID
        self.projectName = projectName
    }
}

struct ProjectBreakdown: Identifiable, Equatable {
    let projectID: UUID?
    let projectName: String
    let minutes: Int
    let blocks: Int
    var id: String { projectID?.uuidString ?? "__no_project__" }
}

struct WeeklyFocusDay: Identifiable {
    let date: Date
    let blocks: Int
    let minutes: Int
    var id: Date { date }
}

private struct FocusJournalState: Codable {
    var day: Date
    var priorities: [String]
    var dailyGoal: Int
    var currentBlockLabel: String
    var previousFocus: String?
    var blockLogs: [FocusBlockLog]
    var currentProjectID: UUID?
}

@MainActor
final class FocusJournal: ObservableObject {
    @Published var day: Date { didSet { save() } }
    @Published var priorities: [String] { didSet { save() } }
    @Published var dailyGoal: Int { didSet { save() } }
    @Published var currentBlockLabel: String { didSet { save() } }
    @Published var previousFocus: String? { didSet { save() } }
    @Published private(set) var blockLogs: [FocusBlockLog] { didSet { save() } }
    @Published private(set) var pendingBlock: FocusBlockLog?
    @Published var currentProjectID: UUID? { didSet { save() } }
    weak var projectLibrary: FocusProjectLibrary?

    private let ud = UserDefaults.shared
    private let key = "focusJournalState"

    init() {
        let today = Calendar.current.startOfDay(for: Date())
        if let data = ud.data(forKey: key),
           let state = try? JSONDecoder().decode(FocusJournalState.self, from: data) {
            let savedDay = Calendar.current.startOfDay(for: state.day)
            if Calendar.current.isDate(savedDay, inSameDayAs: today) {
                day = savedDay
                priorities = state.priorities
                dailyGoal = state.dailyGoal
                currentBlockLabel = state.currentBlockLabel
                previousFocus = state.previousFocus
                blockLogs = state.blockLogs
                currentProjectID = state.currentProjectID
            } else {
                let lastFocus = state.priorities.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                    ?? state.currentBlockLabel.nilIfBlank
                day = today
                priorities = []
                dailyGoal = state.dailyGoal
                currentBlockLabel = lastFocus ?? ""
                previousFocus = lastFocus
                blockLogs = state.blockLogs
                currentProjectID = state.currentProjectID
            }
        } else {
            day = today
            priorities = []
            dailyGoal = 4
            currentBlockLabel = ""
            previousFocus = nil
            blockLogs = []
            currentProjectID = nil
        }
        trimLogs()
        save()
    }

    var primaryFocus: String {
        priorities.first ?? ""
    }

    var effectiveBlockLabel: String {
        currentBlockLabel.nilIfBlank ?? primaryFocus.nilIfBlank ?? "Focus block"
    }

    var needsCheckIn: Bool {
        priorities.allSatisfy { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    func startDay(with focus: String) {
        let clean = focus.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        priorities = [clean]
        currentBlockLabel = clean
        previousFocus = nil
    }

    func continuePreviousFocus() {
        guard let previousFocus, !previousFocus.isEmpty else { return }
        startDay(with: previousFocus)
    }

    func setPrimaryFocus(_ focus: String) {
        let clean = focus.trimmingCharacters(in: .whitespacesAndNewlines)
        priorities = clean.isEmpty ? [] : [clean]
        if currentBlockLabel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            currentBlockLabel = clean
        }
    }

    func resetToday(keepPrevious: Bool = true) {
        let focusToRemember = keepPrevious ? (primaryFocus.nilIfBlank ?? currentBlockLabel.nilIfBlank ?? previousFocus) : previousFocus
        day = Calendar.current.startOfDay(for: Date())
        priorities = []
        currentBlockLabel = ""
        previousFocus = focusToRemember
        pendingBlock = nil
        blockLogs.removeAll { Calendar.current.isDateInToday($0.date) }
    }

    func recordCompletedWork(minutes: Int) {
        let project = projectLibrary?.project(for: currentProjectID)
        pendingBlock = FocusBlockLog(
            date: Date(),
            label: effectiveBlockLabel,
            minutes: minutes,
            outcome: .good,
            projectID: project?.id,
            projectName: project?.name
        )
        save()
    }

    func resolvePendingBlock(as outcome: FocusOutcome, keepLog: Bool = true) {
        guard var block = pendingBlock else { return }
        pendingBlock = nil
        block.outcome = outcome
        if keepLog {
            blockLogs.append(block)
            trimLogs()
        } else {
            save()
        }
    }

    func logsToday() -> [FocusBlockLog] {
        blockLogs.filter { Calendar.current.isDateInToday($0.date) }
    }

    func focusedMinutesToday() -> Int {
        logsToday()
            .filter { $0.outcome != .skipped }
            .reduce(0) { $0 + $1.minutes }
    }

    func focusDaysThisWeek() -> Int {
        guard let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return 0
        }
        let days = blockLogs
            .filter { $0.date >= startOfWeek && $0.outcome != .skipped }
            .map { Calendar.current.startOfDay(for: $0.date) }
        return Set(days).count
    }

    func weeklyReviewDays() -> [WeeklyFocusDay] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let logs = blockLogs.filter { calendar.isDate($0.date, inSameDayAs: day) && $0.outcome != .skipped }
            let minutes = logs.reduce(0) { $0 + $1.minutes }
            return WeeklyFocusDay(date: day, blocks: logs.count, minutes: minutes)
        }
    }

    func topLabelsThisWeek(limit: Int = 3) -> [(label: String, count: Int)] {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }
        let counts = blockLogs
            .filter { $0.date >= startOfWeek && $0.outcome != .skipped }
            .reduce(into: [String: Int]()) { result, log in
                result[log.label, default: 0] += 1
            }
        return counts
            .sorted { lhs, rhs in
                lhs.value == rhs.value ? lhs.key < rhs.key : lhs.value > rhs.value
            }
            .prefix(limit)
            .map { (label: $0.key, count: $0.value) }
    }

    func topProjectsThisWeek(limit: Int = 4) -> [(projectName: String, minutes: Int, blocks: Int)] {
        weeklyProjectBreakdown()
            .prefix(limit)
            .map { (projectName: $0.projectName, minutes: $0.minutes, blocks: $0.blocks) }
    }

    func weeklyProjectBreakdown() -> [ProjectBreakdown] {
        let calendar = Calendar.current
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())) else {
            return []
        }
        struct Bucket { var name: String; var minutes: Int = 0; var blocks: Int = 0 }
        var buckets: [UUID?: Bucket] = [:]
        for log in blockLogs where log.date >= startOfWeek && log.outcome != .skipped {
            let resolvedName: String
            if let id = log.projectID, let live = projectLibrary?.project(for: id) {
                resolvedName = live.name
            } else if let pname = log.projectName, !pname.isEmpty {
                resolvedName = pname
            } else {
                resolvedName = "No Project"
            }
            var bucket = buckets[log.projectID] ?? Bucket(name: resolvedName)
            bucket.name = resolvedName
            bucket.minutes += log.minutes
            bucket.blocks += 1
            buckets[log.projectID] = bucket
        }
        return buckets
            .map { ProjectBreakdown(projectID: $0.key, projectName: $0.value.name, minutes: $0.value.minutes, blocks: $0.value.blocks) }
            .sorted { lhs, rhs in
                if lhs.minutes != rhs.minutes { return lhs.minutes > rhs.minutes }
                return lhs.projectName < rhs.projectName
            }
    }

    private func trimLogs() {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        blockLogs = blockLogs.filter { $0.date >= cutoff }
    }

    private func save() {
        let state = FocusJournalState(
            day: day,
            priorities: priorities,
            dailyGoal: dailyGoal,
            currentBlockLabel: currentBlockLabel,
            previousFocus: previousFocus,
            blockLogs: blockLogs,
            currentProjectID: currentProjectID
        )
        if let data = try? JSONEncoder().encode(state) {
            ud.set(data, forKey: key)
        }
    }
}
