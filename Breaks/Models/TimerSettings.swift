//
//  TimerSettings.swift
//  Breaks
//
//  User-tunable settings, persisted to UserDefaults via per-property didSet.
//

import SwiftUI
import Combine
import Carbon

// MARK: - Settings Model

@MainActor
final class TimerSettings: ObservableObject {
    static let availableSounds = [
        "Glass", "Tink", "Pop", "Hero", "Submarine", "Ping",
        "Funk", "Frog", "Blow", "Bottle", "Morse", "Purr", "Sosumi"
    ]

    @Published var workMinutes: Int       { didSet { ud.set(workMinutes, forKey: "workMinutes") } }
    @Published var shortMinutes: Int      { didSet { ud.set(shortMinutes, forKey: "shortMinutes") } }
    @Published var longMinutes: Int       { didSet { ud.set(longMinutes, forKey: "longMinutes") } }
    @Published var sessionsPerCycle: Int  { didSet { ud.set(sessionsPerCycle, forKey: "sessionsPerCycle") } }
    @Published var autoCycle: Bool        { didSet { ud.set(autoCycle, forKey: "autoCycle") } }
    @Published var soundName: String      { didSet { ud.set(soundName, forKey: "soundName") } }
    @Published var volume: Double         { didSet { ud.set(volume, forKey: "volume") } }
    @Published var lastMode: String       { didSet { ud.set(lastMode, forKey: "lastMode") } }
    @Published var flowMode: Bool         { didSet { ud.set(flowMode, forKey: "flowMode") } }
    @Published var accentColorHex: String { didSet { ud.set(accentColorHex, forKey: "accentColorHex") } }
    @Published var hasCompletedOnboarding: Bool { didSet { ud.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") } }
    @Published var idleDetectionEnabled: Bool { didSet { ud.set(idleDetectionEnabled, forKey: "idleDetectionEnabled") } }
    @Published var idleThresholdMinutes: Int { didSet { ud.set(idleThresholdMinutes, forKey: "idleThresholdMinutes") } }
    @Published var pauseDaysPerWeek: Int { didSet { ud.set(pauseDaysPerWeek, forKey: "pauseDaysPerWeek") } }
    @Published var startHotkeyKeyCode: Int { didSet { ud.set(startHotkeyKeyCode, forKey: "startHotkeyKeyCode") } }
    @Published var startHotkeyModifiers: Int { didSet { ud.set(startHotkeyModifiers, forKey: "startHotkeyModifiers") } }
    @Published var skipHotkeyKeyCode: Int { didSet { ud.set(skipHotkeyKeyCode, forKey: "skipHotkeyKeyCode") } }
    @Published var skipHotkeyModifiers: Int { didSet { ud.set(skipHotkeyModifiers, forKey: "skipHotkeyModifiers") } }
    @Published var resetHotkeyKeyCode: Int { didSet { ud.set(resetHotkeyKeyCode, forKey: "resetHotkeyKeyCode") } }
    @Published var resetHotkeyModifiers: Int { didSet { ud.set(resetHotkeyModifiers, forKey: "resetHotkeyModifiers") } }
    @Published var calendarExportEnabled: Bool { didSet { ud.set(calendarExportEnabled, forKey: "calendarExportEnabled") } }
    @Published var calendarExportIdentifier: String { didSet { ud.set(calendarExportIdentifier, forKey: "calendarExportIdentifier") } }
    @Published private(set) var launchAtLogin: Bool
    @Published private(set) var loginItemError: String?

    private let ud = UserDefaults.shared

    init() {
        let ud = UserDefaults.shared
        workMinutes      = (ud.object(forKey: "workMinutes") as? Int) ?? 25
        shortMinutes     = (ud.object(forKey: "shortMinutes") as? Int) ?? 5
        longMinutes      = (ud.object(forKey: "longMinutes") as? Int) ?? 10
        sessionsPerCycle = (ud.object(forKey: "sessionsPerCycle") as? Int) ?? 4
        autoCycle        = (ud.object(forKey: "autoCycle") as? Bool) ?? true
        soundName        = (ud.object(forKey: "soundName") as? String) ?? "Glass"
        volume           = (ud.object(forKey: "volume") as? Double) ?? 0.7
        lastMode         = (ud.object(forKey: "lastMode") as? String) ?? BreakTimer.Mode.work.rawValue
        flowMode         = (ud.object(forKey: "flowMode") as? Bool) ?? false
        accentColorHex   = (ud.object(forKey: "accentColorHex") as? String) ?? "AccentColor"
        hasCompletedOnboarding = (ud.object(forKey: "hasCompletedOnboarding") as? Bool) ?? false
        idleDetectionEnabled = (ud.object(forKey: "idleDetectionEnabled") as? Bool) ?? true
        idleThresholdMinutes = (ud.object(forKey: "idleThresholdMinutes") as? Int) ?? 5
        pauseDaysPerWeek = (ud.object(forKey: "pauseDaysPerWeek") as? Int) ?? 1
        startHotkeyKeyCode = (ud.object(forKey: "startHotkeyKeyCode") as? Int) ?? Int(kVK_ANSI_B)
        startHotkeyModifiers = (ud.object(forKey: "startHotkeyModifiers") as? Int) ?? Int(cmdKey + optionKey)
        skipHotkeyKeyCode = (ud.object(forKey: "skipHotkeyKeyCode") as? Int) ?? Int(kVK_ANSI_S)
        skipHotkeyModifiers = (ud.object(forKey: "skipHotkeyModifiers") as? Int) ?? Int(cmdKey + optionKey)
        resetHotkeyKeyCode = (ud.object(forKey: "resetHotkeyKeyCode") as? Int) ?? Int(kVK_ANSI_R)
        resetHotkeyModifiers = (ud.object(forKey: "resetHotkeyModifiers") as? Int) ?? Int(cmdKey + optionKey)
        calendarExportEnabled = (ud.object(forKey: "calendarExportEnabled") as? Bool) ?? false
        calendarExportIdentifier = (ud.object(forKey: "calendarExportIdentifier") as? String) ?? ""
        launchAtLogin    = LoginItemController.isEnabled
    }

    func minutes(for mode: BreakTimer.Mode) -> Int {
        switch mode {
        case .work: return workMinutes
        case .shortBreak: return shortMinutes
        case .longBreak: return longMinutes
        }
    }

    var accentColor: Color {
        Color(hex: accentColorHex) ?? .accentColor
    }

    func setAccentColor(_ color: Color) {
        guard let hex = color.toHex() else { return }
        accentColorHex = hex
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func applyPreset(_ preset: DurationPreset) {
        workMinutes = preset.workMinutes
        shortMinutes = preset.shortMinutes
        longMinutes = preset.longMinutes
        sessionsPerCycle = preset.sessionsPerCycle
    }

    func setHotkey(_ action: HotkeyAction, keyCode: Int? = nil, modifiers: Int? = nil) {
        switch action {
        case .startPause:
            startHotkeyKeyCode = keyCode ?? startHotkeyKeyCode
            startHotkeyModifiers = modifiers ?? startHotkeyModifiers
        case .skip:
            skipHotkeyKeyCode = keyCode ?? skipHotkeyKeyCode
            skipHotkeyModifiers = modifiers ?? skipHotkeyModifiers
        case .resetCycle:
            resetHotkeyKeyCode = keyCode ?? resetHotkeyKeyCode
            resetHotkeyModifiers = modifiers ?? resetHotkeyModifiers
        }
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LoginItemController.setEnabled(enabled)
            launchAtLogin = LoginItemController.isEnabled
            loginItemError = nil
        } catch {
            launchAtLogin = LoginItemController.isEnabled
            loginItemError = "Could not update login item: \(error.localizedDescription)"
        }
    }

    func refreshLaunchAtLoginStatus() {
        launchAtLogin = LoginItemController.isEnabled
    }
}

// MARK: - Duration Presets

struct DurationPreset: Identifiable, Equatable {
    let id: String
    let title: String
    let workMinutes: Int
    let shortMinutes: Int
    let longMinutes: Int
    let sessionsPerCycle: Int

    static let all: [DurationPreset] = [
        DurationPreset(id: "pomodoro", title: "Pomodoro", workMinutes: 25, shortMinutes: 5, longMinutes: 10, sessionsPerCycle: 4),
        DurationPreset(id: "deep", title: "Deep Work", workMinutes: 50, shortMinutes: 10, longMinutes: 20, sessionsPerCycle: 3),
        DurationPreset(id: "quick", title: "Quick", workMinutes: 15, shortMinutes: 3, longMinutes: 10, sessionsPerCycle: 4)
    ]
}
