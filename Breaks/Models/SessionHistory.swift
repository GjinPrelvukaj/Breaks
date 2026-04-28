import Foundation
import Combine

struct SessionRecord: Codable {
    let date: Date
    var completedSessions: Int  // number of Pomodoros completed on that day
}

enum DayStatus: Equatable {
    case completed(Int)   // sessions count
    case pause            // counted as rest day, no decay
    case missed           // decayed -1
    case upcoming         // future
    case today            // today, not yet evaluated
}

struct StreakSnapshot {
    let streak: Int
    let pauseDaysUsedThisWeek: Int
    let pauseDayBudget: Int
    let statusByDay: [Date: DayStatus]
}

@MainActor
final class SessionHistory: ObservableObject {
    @Published private(set) var records: [SessionRecord] = []
    private let ud = UserDefaults.shared
    private let key = "sessionHistory"
    private let retentionDays = 120

    init() {
        load()
    }

    func addCompletion() {
        let today = Calendar.current.startOfDay(for: Date())
        if let index = records.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) {
            records[index].completedSessions += 1
        } else {
            records.append(SessionRecord(date: today, completedSessions: 1))
        }
        prune()
        save()
    }

    func removeCompletionToday() {
        let today = Calendar.current.startOfDay(for: Date())
        guard let index = records.firstIndex(where: { Calendar.current.isDate($0.date, inSameDayAs: today) }) else { return }
        records[index].completedSessions = max(0, records[index].completedSessions - 1)
        if records[index].completedSessions == 0 {
            records.remove(at: index)
        }
        save()
    }

    func clearToday() {
        records.removeAll { Calendar.current.isDateInToday($0.date) }
        save()
    }

    func completions(on day: Date) -> Int {
        records
            .filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
            .reduce(0) { $0 + $1.completedSessions }
    }

    func totalThisWeek() -> Int {
        let startOfWeek = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return records.filter { $0.date >= startOfWeek }.reduce(0) { $0 + $1.completedSessions }
    }

    func totalToday() -> Int {
        records
            .filter { Calendar.current.isDateInToday($0.date) }
            .reduce(0) { $0 + $1.completedSessions }
    }

    /// Decay-aware streak. Missed day = -1 (floor 0). Pause day = no change, up to `pauseDayBudget` per ISO week.
    /// Pauses are allocated greedily inside each week: first missed day in week uses the budget.
    func streakSnapshot(pauseDayBudget: Int, lookbackDays: Int = 84) -> StreakSnapshot {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let earliestRecord = records.map { calendar.startOfDay(for: $0.date) }.min()
        let lookbackStart = calendar.date(byAdding: .day, value: -lookbackDays, to: today) ?? today
        let epoch = earliestRecord.map { max($0, lookbackStart) } ?? today

        let completedSessions: [Date: Int] = records.reduce(into: [:]) { acc, rec in
            let day = calendar.startOfDay(for: rec.date)
            acc[day, default: 0] += rec.completedSessions
        }

        var streak = 0
        var pauseUsedByWeek: [String: Int] = [:]
        var status: [Date: DayStatus] = [:]
        let budget = max(0, pauseDayBudget)

        var day = epoch
        while day <= today {
            let comps = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: day)
            let weekKey = "\(comps.yearForWeekOfYear ?? 0)-\(comps.weekOfYear ?? 0)"
            let count = completedSessions[day] ?? 0

            if calendar.isDate(day, inSameDayAs: today) {
                if count > 0 {
                    streak += 1
                    status[day] = .completed(count)
                } else {
                    status[day] = .today
                }
            } else if count > 0 {
                streak += 1
                status[day] = .completed(count)
            } else {
                let used = pauseUsedByWeek[weekKey, default: 0]
                if used < budget {
                    pauseUsedByWeek[weekKey] = used + 1
                    status[day] = .pause
                } else {
                    streak = max(0, streak - 1)
                    status[day] = .missed
                }
            }

            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }

        let thisWeekKey: String = {
            let c = calendar.dateComponents([.weekOfYear, .yearForWeekOfYear], from: today)
            return "\(c.yearForWeekOfYear ?? 0)-\(c.weekOfYear ?? 0)"
        }()
        let pauseUsedThisWeek = pauseUsedByWeek[thisWeekKey, default: 0]

        return StreakSnapshot(
            streak: streak,
            pauseDaysUsedThisWeek: pauseUsedThisWeek,
            pauseDayBudget: budget,
            statusByDay: status
        )
    }

    func currentStreak(pauseDayBudget: Int = 0) -> Int {
        streakSnapshot(pauseDayBudget: pauseDayBudget).streak
    }

    func totalAllTime() -> Int {
        records.reduce(0) { $0 + $1.completedSessions }
    }

    private func prune() {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -retentionDays, to: calendar.startOfDay(for: Date())) ?? Date.distantPast
        records = records
            .filter { $0.date >= cutoff }
            .sorted { $0.date > $1.date }
    }

    private func load() {
        if let data = ud.data(forKey: key), let decoded = try? JSONDecoder().decode([SessionRecord].self, from: data) {
            records = decoded
            prune()
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(records) {
            ud.set(data, forKey: key)
        }
    }
}
