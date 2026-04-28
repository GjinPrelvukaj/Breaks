import Foundation

// Shared storage layer used by the main app and (forthcoming) widget extension.
// When the widget target ships, add the App Group entitlement
// (`group.com.gjinprelvukaj.Breaks`) to both targets and flip
// `UserDefaults.shared` to `UserDefaults(suiteName: AppGroup.id) ?? .standard`,
// then run a one-time migration copying keys from `.standard` into the suite.

enum AppGroup {
    static let id = "group.com.gjinprelvukaj.Breaks"
}

extension UserDefaults {
    static let shared: UserDefaults = .standard
}

enum TimerStorageKey {
    static let mode = "timerMode"
    static let remaining = "timerRemaining"
    static let isRunning = "timerIsRunning"
    static let endDate = "timerEndDate"
    static let completedWorkSessions = "completedWorkSessions"
}

enum SettingsStorageKey {
    static let workMinutes = "workMinutes"
    static let shortMinutes = "shortMinutes"
    static let longMinutes = "longMinutes"
    static let sessionsPerCycle = "sessionsPerCycle"
    static let lastMode = "lastMode"
    static let accentColorHex = "accentColorHex"
}

struct TimerSnapshot {
    enum ModeKind: String { case work = "Work", shortBreak = "Short Break", longBreak = "Long Break" }

    let mode: ModeKind
    let isRunning: Bool
    let endDate: Date?
    let remainingSeconds: Int
    let completedWorkSessions: Int
    let sessionsPerCycle: Int

    static func read(from defaults: UserDefaults = .shared) -> TimerSnapshot {
        let modeRaw = defaults.object(forKey: TimerStorageKey.mode) as? String ?? ModeKind.work.rawValue
        let mode = ModeKind(rawValue: modeRaw) ?? .work
        return TimerSnapshot(
            mode: mode,
            isRunning: (defaults.object(forKey: TimerStorageKey.isRunning) as? Bool) ?? false,
            endDate: defaults.object(forKey: TimerStorageKey.endDate) as? Date,
            remainingSeconds: (defaults.object(forKey: TimerStorageKey.remaining) as? Int) ?? 0,
            completedWorkSessions: (defaults.object(forKey: TimerStorageKey.completedWorkSessions) as? Int) ?? 0,
            sessionsPerCycle: (defaults.object(forKey: SettingsStorageKey.sessionsPerCycle) as? Int) ?? 4
        )
    }
}
