//
//  BreakTimer.swift
//  Breaks
//
//  Core timer controller: mode cycling, idle detection, sleep/wake, notifications.
//

import SwiftUI
import Combine
import UserNotifications
import AppKit

// MARK: - Idle Prompt

struct IdlePrompt: Identifiable {
    let id = UUID()
    let idleSeconds: TimeInterval
}

// MARK: - Tick Clock

// `TimerStorageKey` lives in `SharedStorage.swift` so the widget extension
// can read the same keys.

@MainActor
final class TickClock: ObservableObject {
    @Published var remaining: Int = 0
}

// MARK: - Timer Logic

final class BreakTimer: ObservableObject {
    enum Mode: String, CaseIterable, Identifiable {
        case work = "Work"
        case shortBreak = "Short Break"
        case longBreak = "Long Break"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .work: return "brain.head.profile"
            case .shortBreak: return "cup.and.saucer"
            case .longBreak: return "leaf"
            }
        }
        var shortLabel: String {
            switch self {
            case .work: return "Focus"
            case .shortBreak: return "Short"
            case .longBreak: return "Long"
            }
        }
    }

    let settings: TimerSettings
    let history = SessionHistory()
    let journal = FocusJournal()
    let clock = TickClock()

    @Published private(set) var mode: Mode
    @Published private(set) var duration: Int
    /// Action-boundary remaining (start/pause/reset/setMode/fire). Per-tick
    /// updates happen on `clock.remaining` so the popover doesn't cascade
    /// re-renders every second.
    @Published private(set) var remaining: Int {
        didSet { clock.remaining = remaining }
    }
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var completedWorkSessions: Int = 0 {
        didSet { persistTimerState() }
    }
    @Published var idlePrompt: IdlePrompt?

    private var ticker: Timer?
    private var endDate: Date?
    private var permissionRequested = false
    private var bag = Set<AnyCancellable>()
    var flowMode: Bool { settings.flowMode }

    init() {
        let s = TimerSettings()
        self.settings = s
        let ud = UserDefaults.shared
        let restoredMode = Mode(rawValue: (ud.object(forKey: TimerStorageKey.mode) as? String) ?? s.lastMode) ?? .work
        self.mode = restoredMode
        let d = s.minutes(for: restoredMode) * 60
        self.duration = d
        self.completedWorkSessions = (ud.object(forKey: TimerStorageKey.completedWorkSessions) as? Int) ?? 0

        if let savedEndDate = ud.object(forKey: TimerStorageKey.endDate) as? Date,
           (ud.object(forKey: TimerStorageKey.isRunning) as? Bool) == true,
           savedEndDate > Date() {
            self.remaining = max(1, Int(savedEndDate.timeIntervalSinceNow.rounded()))
            self.isRunning = true
            self.endDate = savedEndDate
            scheduleTicker()
        } else if let savedRemaining = ud.object(forKey: TimerStorageKey.remaining) as? Int,
                  savedRemaining > 0,
                  savedRemaining <= d {
            self.remaining = savedRemaining
        } else {
            self.remaining = d
            clearExpiredRunningState()
        }
        clock.remaining = remaining

        // Only auto-request for legacy users who already onboarded; new users
        // grant explicitly from the onboarding screen.
        if s.hasCompletedOnboarding {
            Task { await requestPermissionIfNeeded() }
        }

        s.objectWillChange
            .sink { [weak self] in
                DispatchQueue.main.async { self?.refreshIdleDuration() }
            }
            .store(in: &bag)

        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(self, selector: #selector(handleSleep),
                       name: NSWorkspace.willSleepNotification, object: nil)
        ws.addObserver(self, selector: #selector(handleWake),
                       name: NSWorkspace.didWakeNotification, object: nil)

        // Save state on quit
        NotificationCenter.default.addObserver(self, selector: #selector(saveStateOnQuit),
                                               name: NSApplication.willTerminateNotification, object: nil)
    }

    deinit {
        ticker?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: Display
    var menuIcon: String { isRunning ? mode.icon : "timer" }

    func menuBarTitle(for current: Int) -> String? {
        guard isRunning || current != duration else { return nil }
        return formatted(current)
    }

    func formatted(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    // MARK: Actions
    func setMode(_ mode: Mode) {
        stopTicker()
        self.mode = mode
        settings.lastMode = mode.rawValue
        let d = settings.minutes(for: mode) * 60
        duration = d
        remaining = d
        persistTimerState()
    }

    func start() {
        guard !isRunning, remaining > 0 else { return }
        if journal.needsCheckIn {
            journal.startDay(with: "Focus")
        }
        idlePrompt = nil
        isRunning = true
        endDate = Date().addingTimeInterval(TimeInterval(remaining))
        scheduleTicker()
        persistTimerState()
    }

    func pause() {
        guard isRunning else { return }
        syncRemaining()
        stopTicker()
        persistTimerState()
    }

    func reset() {
        stopTicker()
        remaining = duration
        persistTimerState()
    }

    func skip() {
        let wasRunning = isRunning
        stopTicker()
        advanceMode()
        if wasRunning { start() }
    }

    func resetCycle() {
        stopTicker()
        completedWorkSessions = 0
        setMode(.work)
        persistTimerState()
    }

    func resetToday() {
        stopTicker()
        completedWorkSessions = 0
        history.clearToday()
        journal.resetToday()
        setMode(.work)
        persistTimerState()
    }

    func resolvePendingBlock(as outcome: FocusOutcome) {
        if outcome == .skipped {
            history.removeCompletionToday()
            completedWorkSessions = max(0, completedWorkSessions - 1)
            journal.resolvePendingBlock(as: outcome, keepLog: false)
        } else {
            journal.resolvePendingBlock(as: outcome)
        }
        if settings.autoCycle, !isRunning, mode != .work, remaining > 0 {
            start()
        }
    }

    func resumeAfterIdle() {
        idlePrompt = nil
        start()
    }

    func resetAfterIdle() {
        idlePrompt = nil
        reset()
    }

    // MARK: Internals
    private func refreshIdleDuration() {
        guard !isRunning else { return }
        let new = settings.minutes(for: mode) * 60
        if duration != new {
            duration = new
            remaining = new
            persistTimerState()
        }
    }

    private func syncRemaining() {
        guard let endDate else { return }
        remaining = max(0, Int(endDate.timeIntervalSinceNow.rounded()))
    }

    private func scheduleTicker() {
        ticker?.invalidate()
        let t = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
        t.tolerance = 0.15
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func stopTicker() {
        isRunning = false
        ticker?.invalidate()
        ticker = nil
        endDate = nil
    }

    private func tick() {
        guard let endDate else { return }
        let secs = max(0, Int(endDate.timeIntervalSinceNow.rounded()))
        // Per-tick updates write only to `clock` so the popover does not
        // re-render the entire view tree every second. `remaining` is only
        // touched on action boundaries (start/pause/reset/setMode/fire).
        clock.remaining = secs
        detectIdleIfNeeded()
        if secs <= 0 {
            remaining = 0
            fire()
        }
    }

    private func detectIdleIfNeeded() {
        guard settings.idleDetectionEnabled,
              idlePrompt == nil,
              isRunning,
              mode == .work else { return }
        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: ~0)!
        )
        guard idleSeconds >= TimeInterval(settings.idleThresholdMinutes * 60) else { return }
        syncRemaining()
        stopTicker()
        // Restore the wasted seconds so the user doesn't lose timer time while away.
        let restored = min(duration, remaining + Int(idleSeconds))
        remaining = max(0, restored)
        idlePrompt = IdlePrompt(idleSeconds: idleSeconds)
        persistTimerState()
    }

    private func fire() {
        let finished = mode
        stopTicker()
        remaining = 0
        playSound()
        postNotification(for: finished)

        if finished == .work {
            completedWorkSessions += 1
            history.addCompletion()
            journal.recordCompletedWork(minutes: settings.workMinutes)
        } else if finished == .longBreak {
            completedWorkSessions = 0
        }

        if settings.autoCycle {
            advanceMode()
            start()
        } else {
            persistTimerState()
        }
    }

    private func advanceMode() {
        let next: Mode
        switch mode {
        case .work:
            let done = completedWorkSessions
            next = (done > 0 && done % settings.sessionsPerCycle == 0) ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            next = .work
        }
        mode = next
        settings.lastMode = next.rawValue
        let d = settings.minutes(for: next) * 60
        duration = d
        remaining = d
        persistTimerState()
    }

    @objc private func handleSleep() {
        ticker?.invalidate()
        ticker = nil
    }

    @objc private func handleWake() {
        guard isRunning else { return }
        if let endDate, endDate.timeIntervalSinceNow <= 0 {
            remaining = 0
            fire()
        } else {
            syncRemaining()
            scheduleTicker()
            persistTimerState()
        }
    }

    @objc private func saveStateOnQuit() {
        if isRunning { syncRemaining() }
        persistTimerState()
    }

    private func persistTimerState() {
        let ud = UserDefaults.shared
        ud.set(mode.rawValue, forKey: TimerStorageKey.mode)
        ud.set(remaining, forKey: TimerStorageKey.remaining)
        ud.set(isRunning, forKey: TimerStorageKey.isRunning)
        ud.set(completedWorkSessions, forKey: TimerStorageKey.completedWorkSessions)
        if isRunning, let endDate {
            ud.set(endDate, forKey: TimerStorageKey.endDate)
        } else {
            ud.removeObject(forKey: TimerStorageKey.endDate)
        }
    }

    private func clearExpiredRunningState() {
        let ud = UserDefaults.shared
        ud.removeObject(forKey: TimerStorageKey.endDate)
        ud.removeObject(forKey: "savedEndDate")
        ud.removeObject(forKey: "savedRemaining")
    }

    // MARK: Notifications + Sound
    private func requestPermissionIfNeeded() async {
        guard !permissionRequested else { return }
        permissionRequested = true
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
    }

    private func postNotification(for mode: Mode) {
        let content = UNMutableNotificationContent()
        content.title = "\(mode.rawValue) finished"
        content.body = mode == .work ? "Time for a break." : "Back to focus."
        content.sound = .default
        content.threadIdentifier = "breaks.timer"
        let identifier = "breaks.timer.\(mode.rawValue.lowercased().replacingOccurrences(of: " ", with: "-"))"
        let req = UNNotificationRequest(identifier: identifier,
                                        content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        center.add(req)
    }

    private func playSound() {
        guard let sound = NSSound(named: NSSound.Name(settings.soundName)) else { return }
        sound.volume = Float(settings.volume)
        sound.play()
    }
}
