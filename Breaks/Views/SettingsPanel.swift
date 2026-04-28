//
//  SettingsPanel.swift
//  Breaks
//
//  Settings page with collapsible sections for all user-tunable options.
//

import SwiftUI
import AppKit

// MARK: - Settings Panel

struct SettingsPanel: View {
    @ObservedObject var settings: TimerSettings
    @ObservedObject var hotkeyManager: HotkeyManager
    @ObservedObject var library: BreakSuggestionLibrary
    @ObservedObject var calendar: CalendarExporter
    @StateObject private var permissions = NotificationPermissions()
    @Binding var showing: Bool
    @State private var collapsed: Set<SettingsSection> = []

    enum SettingsSection: String, CaseIterable, Identifiable {
        case durations, cycle, streak, focusGuard, appearance, breakSuggestions, calendarExport, permissions, sound, hotkeys
        var id: String { rawValue }
        var title: String {
            switch self {
            case .durations: return "Durations"
            case .cycle: return "Cycle"
            case .streak: return "Streak"
            case .focusGuard: return "Focus guard"
            case .appearance: return "Appearance"
            case .breakSuggestions: return "Break suggestions"
            case .calendarExport: return "Calendar export"
            case .permissions: return "Permissions"
            case .sound: return "Sound"
            case .hotkeys: return "Global Hotkeys"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ZStack {
                    Text("Settings").font(.headline)
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

                ForEach(SettingsSection.allCases) { section in
                    CollapsibleSection(
                        title: section.title,
                        expanded: !collapsed.contains(section),
                        toggle: { toggle(section) }
                    ) {
                        sectionContent(for: section)
                    }
                    if section != SettingsSection.allCases.last {
                        Divider()
                    }
                }

                Divider()
                AppInfoFooter()
            }
            .padding(16)
            .animation(.spring(response: 0.32, dampingFraction: 0.85), value: collapsed)
        }
        .frame(height: 540)
        .tint(settings.accentColor)
        .onAppear { settings.refreshLaunchAtLoginStatus() }
    }

    private func toggle(_ section: SettingsSection) {
        if collapsed.contains(section) {
            collapsed.remove(section)
        } else {
            collapsed.insert(section)
        }
    }

    @ViewBuilder
    private func sectionContent(for section: SettingsSection) -> some View {
        switch section {
        case .durations: durationsSection
        case .cycle: cycleSection
        case .streak: streakSection
        case .focusGuard: focusGuardSection
        case .appearance: appearanceSection
        case .breakSuggestions: breakSuggestionsSection
        case .calendarExport: calendarExportSection
        case .permissions: permissionsSection
        case .sound: soundSection
        case .hotkeys: hotkeysSection
        }
    }

    @ViewBuilder
    private var durationsSection: some View {
        MinuteRow(label: "Work",        value: $settings.workMinutes,  range: 1...90)
        MinuteRow(label: "Short Break", value: $settings.shortMinutes, range: 1...30)
        MinuteRow(label: "Long Break",  value: $settings.longMinutes,  range: 1...60)
        HStack(spacing: 6) {
            ForEach(DurationPreset.all) { preset in
                DurationPresetButton(
                    preset: preset,
                    selected: isSelected(preset),
                    accentColor: settings.accentColor
                ) {
                    settings.applyPreset(preset)
                }
            }
        }
    }

    @ViewBuilder
    private var cycleSection: some View {
        Toggle("Auto-cycle phases", isOn: $settings.autoCycle)
            .toggleStyle(.switch)
        MinuteRow(label: "Sessions per cycle",
                  value: $settings.sessionsPerCycle,
                  range: 2...8,
                  suffix: "")
    }

    @ViewBuilder
    private var streakSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            MinuteRow(label: "Rest days per week",
                      value: $settings.pauseDaysPerWeek,
                      range: 0...3,
                      suffix: settings.pauseDaysPerWeek == 1 ? "day" : "days")
            Text("Miss a regular day → streak −1, not reset. Rest days never decay.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var focusGuardSection: some View {
        Toggle("Pause when I step away", isOn: $settings.idleDetectionEnabled)
            .toggleStyle(.switch)
        MinuteRow(label: "Away threshold",
                  value: $settings.idleThresholdMinutes,
                  range: 1...30,
                  suffix: "min")
    }

    @ViewBuilder
    private var appearanceSection: some View {
        Toggle("Flow mode (icon only, no countdown while running)", isOn: $settings.flowMode)
            .toggleStyle(.switch)
        Toggle("Start at login", isOn: Binding(
            get: { settings.launchAtLogin },
            set: { settings.setLaunchAtLogin($0) }
        ))
        .toggleStyle(.switch)
        if let loginItemError = settings.loginItemError {
            Text(loginItemError)
                .font(.caption)
                .foregroundStyle(.red)
        }
        HStack {
            Text("Accent color")
            Spacer()
            ColorPicker("", selection: Binding(
                get: { settings.accentColor },
                set: { settings.setAccentColor($0) }
            ), supportsOpacity: false)
            .labelsHidden()
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(settings.accentColor)
                .frame(width: 24, height: 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.25), lineWidth: 1)
                )
        }
    }

    @ViewBuilder
    private var breakSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(library.suggestions) { s in
                BreakSuggestionEditorRow(
                    suggestion: s,
                    accentColor: settings.accentColor,
                    onChange: { library.update($0) },
                    onDelete: { library.remove(s.id) }
                )
            }
            HStack(spacing: 6) {
                Button {
                    library.add(BreakSuggestion(text: "New suggestion", symbol: "sparkles", applies: .any))
                } label: {
                    Label("Add", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                Spacer()
                Button("Reset to defaults") { library.resetToDefaults() }
                    .font(.caption)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            Text("Click a suggestion in the timer to cycle through. Library shows during short and long breaks.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var calendarExportSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle("Log finished focus sessions to Calendar", isOn: Binding(
                get: { settings.calendarExportEnabled },
                set: { newValue in
                    if newValue {
                        Task {
                            let granted = await calendar.requestAccess()
                            await MainActor.run {
                                settings.calendarExportEnabled = granted
                            }
                        }
                    } else {
                        settings.calendarExportEnabled = false
                    }
                }
            ))
            .toggleStyle(.switch)
            .disabled(calendar.authState == .denied)

            if calendar.authState == .denied {
                Text("Calendar access denied. Enable in System Settings → Privacy & Security → Calendars.")
                    .font(.caption2)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if settings.calendarExportEnabled,
               (calendar.authState == .granted || calendar.authState == .writeOnly) {
                if calendar.availableCalendars.isEmpty {
                    Text("No writable calendars found. The default calendar will be used.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                } else {
                    HStack {
                        Text("Calendar")
                            .font(.caption)
                        Spacer()
                        Picker("", selection: $settings.calendarExportIdentifier) {
                            Text("Default").tag("")
                            ForEach(calendar.availableCalendars, id: \.id) { cal in
                                Text(cal.title).tag(cal.id)
                            }
                        }
                        .labelsHidden()
                        .frame(maxWidth: 180)
                    }
                }
            }

            if let err = calendar.lastError {
                Text(err)
                    .font(.caption2)
                    .foregroundStyle(.red)
            }

            Text("Each completed focus session becomes a calendar event titled with your current focus.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .onAppear { calendar.refreshAuthState() }
    }

    @ViewBuilder
    private var permissionsSection: some View {
        PermissionRow(permissions: permissions, accentColor: settings.accentColor)
    }

    @ViewBuilder
    private var soundSection: some View {
        HStack {
            Picker("", selection: $settings.soundName) {
                ForEach(TimerSettings.availableSounds, id: \.self) { name in
                    Text(name).tag(name)
                }
            }
            .labelsHidden()
            Button {
                if let s = NSSound(named: NSSound.Name(settings.soundName)) {
                    s.volume = Float(settings.volume)
                    s.play()
                }
            } label: {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(settings.accentColor)
            }
            .buttonStyle(.plain)
            .help("Preview")
        }
        HStack(spacing: 8) {
            Image(systemName: "speaker.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
            Slider(value: $settings.volume, in: 0...1)
            Text("\(Int(settings.volume * 100))%")
                .monospacedDigit()
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 36, alignment: .trailing)
        }
    }

    @ViewBuilder
    private var hotkeysSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(HotkeyAction.allCases) { action in
                HotkeyEditorRow(
                    action: action,
                    keyCode: hotkeyKeyBinding(for: action),
                    modifiers: hotkeyModifierBinding(for: action)
                )
                .onChange(of: hotkeyKeyValue(for: action)) { _ in
                    hotkeyManager.reloadHotkeys(settings: settings)
                }
                .onChange(of: hotkeyModifierValue(for: action)) { _ in
                    hotkeyManager.reloadHotkeys(settings: settings)
                }
            }
        }
        .font(.caption)
    }

    private func isSelected(_ preset: DurationPreset) -> Bool {
        settings.workMinutes == preset.workMinutes &&
        settings.shortMinutes == preset.shortMinutes &&
        settings.longMinutes == preset.longMinutes &&
        settings.sessionsPerCycle == preset.sessionsPerCycle
    }

    private func hotkeyKeyBinding(for action: HotkeyAction) -> Binding<Int> {
        Binding(
            get: { hotkeyKeyValue(for: action) },
            set: { settings.setHotkey(action, keyCode: $0) }
        )
    }

    private func hotkeyModifierBinding(for action: HotkeyAction) -> Binding<Int> {
        Binding(
            get: { hotkeyModifierValue(for: action) },
            set: { settings.setHotkey(action, modifiers: $0) }
        )
    }

    private func hotkeyKeyValue(for action: HotkeyAction) -> Int {
        switch action {
        case .startPause: return settings.startHotkeyKeyCode
        case .skip: return settings.skipHotkeyKeyCode
        case .resetCycle: return settings.resetHotkeyKeyCode
        }
    }

    private func hotkeyModifierValue(for action: HotkeyAction) -> Int {
        switch action {
        case .startPause: return settings.startHotkeyModifiers
        case .skip: return settings.skipHotkeyModifiers
        case .resetCycle: return settings.resetHotkeyModifiers
        }
    }

    private func sectionLabel(_ s: String) -> some View {
        Text(s)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
    }
}

// MARK: - Collapsible Section

struct CollapsibleSection<Content: View>: View {
    let title: String
    let expanded: Bool
    let toggle: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: toggle) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(expanded ? 0 : -90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(alignment: .leading, spacing: 8) {
                    content()
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
    }
}

// MARK: - Break Suggestion Editor Row

struct BreakSuggestionEditorRow: View {
    let suggestion: BreakSuggestion
    let accentColor: Color
    let onChange: (BreakSuggestion) -> Void
    let onDelete: () -> Void

    @State private var text: String
    @State private var symbol: String
    @State private var applies: BreakSuggestion.Applies

    init(suggestion: BreakSuggestion,
         accentColor: Color,
         onChange: @escaping (BreakSuggestion) -> Void,
         onDelete: @escaping () -> Void) {
        self.suggestion = suggestion
        self.accentColor = accentColor
        self.onChange = onChange
        self.onDelete = onDelete
        _text = State(initialValue: suggestion.text)
        _symbol = State(initialValue: suggestion.symbol)
        _applies = State(initialValue: suggestion.applies)
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol.isEmpty ? "sparkles" : symbol)
                .font(.caption)
                .foregroundStyle(accentColor)
                .frame(width: 16)

            TextField("Suggestion", text: $text)
                .textFieldStyle(.plain)
                .font(.caption)
                .onSubmit { commit() }

            TextField("symbol", text: $symbol)
                .textFieldStyle(.plain)
                .font(.caption2)
                .frame(width: 70)
                .foregroundStyle(.secondary)
                .onSubmit { commit() }

            Picker("", selection: $applies) {
                ForEach(BreakSuggestion.Applies.allCases) { a in
                    Text(a.label).tag(a)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .controlSize(.small)
            .frame(width: 70)
            .onChange(of: applies) { _ in commit() }

            Button {
                onDelete()
            } label: {
                Image(systemName: "minus.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 2)
        .onChange(of: text) { _ in commit() }
        .onChange(of: symbol) { _ in commit() }
    }

    private func commit() {
        var updated = suggestion
        updated.text = text
        updated.symbol = symbol
        updated.applies = applies
        onChange(updated)
    }
}
