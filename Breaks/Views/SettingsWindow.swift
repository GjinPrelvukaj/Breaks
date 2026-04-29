//
//  SettingsWindow.swift
//  Breaks
//
//  Native macOS Settings window.
//

import SwiftUI
import AppKit

struct SettingsWindow: View {
    @ObservedObject var timer: BreakTimer
    @ObservedObject var hotkeyManager: HotkeyManager
    @State private var selection: Category = .general

    enum Category: String, CaseIterable, Identifiable, Hashable {
        case general, appearance, shortcuts, projects, misc
        var id: String { rawValue }
        var title: String {
            switch self {
            case .general: return "General"
            case .appearance: return "Appearance"
            case .shortcuts: return "Shortcuts"
            case .projects: return "Projects"
            case .misc: return "More"
            }
        }
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .appearance: return "paintbrush"
            case .shortcuts: return "command"
            case .projects: return "folder"
            case .misc: return "ellipsis.circle"
            }
        }
        var tint: Color {
            switch self {
            case .general: return .gray
            case .appearance: return .pink
            case .shortcuts: return .orange
            case .projects: return .blue
            case .misc: return .gray
            }
        }
        var caption: String {
            switch self {
            case .general: return "Timer durations and cycle"
            case .appearance: return "Window, color, and theme"
            case .shortcuts: return "Global keyboard hotkeys"
            case .projects: return "Tag focus blocks by project"
            case .misc: return "Idle, automation, calendar, sounds"
            }
        }
    }

    private struct Group: Identifiable {
        let id: String
        let title: String
        let items: [Category]
    }

    private static let groups: [Group] = [
        Group(id: "setup", title: "Setup",
              items: [.general, .appearance, .shortcuts]),
        Group(id: "more", title: "More",
              items: [.projects, .misc])
    ]

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                SidebarHeader()
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 18, leading: 0, bottom: 10, trailing: 14))

                ForEach(Self.groups) { group in
                    Section(group.title) {
                        ForEach(group.items) { category in
                            SidebarRow(category: category)
                                .tag(category)
                                .listRowSeparator(.hidden)
                        }
                    }
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                SidebarFooter()
            }
            .navigationSplitViewColumnWidth(min: 215, ideal: 230, max: 280)
        } detail: {
            DetailPage(category: selection) {
                detailContent(for: selection)
            }
            .id(selection)
            .frame(minWidth: 540, idealWidth: 600, maxWidth: .infinity, maxHeight: .infinity)
            .navigationSplitViewColumnWidth(min: 540, ideal: 600)
        }
        .frame(minHeight: 520, idealHeight: 600)
        .background(SettingsWindowChrome())
        .onAppear {
            timer.settings.refreshLaunchAtLoginStatus()
            NSApp.setActivationPolicy(.regular)
            NSApp.activate(ignoringOtherApps: true)
        }
        .onDisappear {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    @ViewBuilder
    private func detailContent(for category: Category) -> some View {
        switch category {
        case .general:
            GeneralTab(settings: timer.settings)
        case .appearance:
            AppearanceTab(settings: timer.settings)
        case .shortcuts:
            ShortcutsTab(settings: timer.settings, hotkeyManager: hotkeyManager)
        case .projects:
            ProjectsTab(projects: timer.projects)
        case .misc:
            MiscTab(
                settings: timer.settings,
                library: timer.suggestions,
                calendar: timer.calendarExporter
            )
        }
    }
}

// MARK: - Window Chrome

private struct SettingsWindowChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async { configure(v.window) }
        return v
    }
    func updateNSView(_ v: NSView, context: Context) {
        DispatchQueue.main.async { configure(v.window) }
    }
    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.title = "Breaks Settings"
        window.titleVisibility = .hidden
        window.toolbarStyle = .unifiedCompact
        window.titlebarAppearsTransparent = false
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarSeparatorStyle = .automatic
        if window.toolbar == nil {
            window.toolbar = NSToolbar()
        }
        if let svc = findSplitVC(window.contentViewController) {
            for item in svc.splitViewItems {
                item.titlebarSeparatorStyle = .none
            }
        }
    }

    private func findSplitVC(_ vc: NSViewController?) -> NSSplitViewController? {
        guard let vc else { return nil }
        if let s = vc as? NSSplitViewController { return s }
        for child in vc.children {
            if let s = findSplitVC(child) { return s }
        }
        return nil
    }
}

// MARK: - Detail Page

private struct DetailPage<Content: View>: View {
    let category: SettingsWindow.Category
    @ViewBuilder var content: Content

    var body: some View {
        Form {
            Section {
                EmptyView()
            } header: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(category.title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                        .textCase(nil)
                    Text(category.caption)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                        .textCase(nil)
                }
                .padding(.top, 2)
                .padding(.bottom, 18)
            }

            content
        }
        .formStyle(.grouped)
    }
}

// MARK: - Sidebar Header

private struct SidebarHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Breaks")
                .font(.system(size: 22, weight: .bold))
            Text("Settings")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Sidebar Footer

private struct SidebarFooter: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider().opacity(0.5)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 26, height: 26)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Breaks")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Version \(version)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                HStack(spacing: 4) {
                    FooterIconButton(symbol: "info.circle", help: "About Breaks") {
                        showAbout()
                    }
                    FooterIconButton(symbol: "questionmark.circle", help: "Help") {
                        if let url = URL(string: "https://github.com/gjinprelvukaj/breaks") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    FooterIconButton(symbol: "envelope", help: "Send feedback") {
                        if let url = URL(string: "mailto:gjinp@7studios.co?subject=Breaks%20feedback") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    Spacer()
                    Button {
                        NSApp.terminate(nil)
                    } label: {
                        Text("Quit")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(Color.primary.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Quit Breaks (⌘Q)")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
    }

    private func showAbout() {
        let credits = NSMutableAttributedString(
            string: "A pomodoro timer that lives in your menu bar.\n\n",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11),
                .foregroundColor: NSColor.labelColor
            ]
        )
        credits.append(NSAttributedString(
            string: "Made by Gjin Prelvukaj",
            attributes: [
                .font: NSFont.systemFont(ofSize: 11, weight: .medium),
                .foregroundColor: NSColor.secondaryLabelColor
            ]
        ))
        NSApp.orderFrontStandardAboutPanel(options: [
            NSApplication.AboutPanelOptionKey.credits: credits,
            NSApplication.AboutPanelOptionKey(rawValue: "Copyright"): "© 2026 Gjin Prelvukaj"
        ])
        NSApp.activate(ignoringOtherApps: true)
    }
}

private struct FooterIconButton: View {
    let symbol: String
    let help: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
                .frame(width: 24, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.primary.opacity(hovering ? 0.08 : 0))
                )
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { hovering = $0 }
    }
}

// MARK: - Sidebar Row

private struct SidebarRow: View {
    let category: SettingsWindow.Category
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: category.icon)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 22, height: 22)
            Text(category.title)
                .font(.system(size: 13))
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(hovering ? 0.06 : 0))
        )
        .contentShape(Rectangle())
        .onHover { hovering = $0 }
    }
}

// MARK: - General

private struct GeneralTab: View {
    @ObservedObject var settings: TimerSettings

    var body: some View {
        Group {
            Section("Durations") {
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

            Section("Cycle") {
                Toggle("Auto-cycle phases", isOn: $settings.autoCycle)
                    .toggleStyle(.switch)
                MinuteRow(label: "Sessions per cycle",
                          value: $settings.sessionsPerCycle,
                          range: 2...8,
                          suffix: "")
            }

            Section("Streak") {
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
    }

    private func isSelected(_ preset: DurationPreset) -> Bool {
        settings.workMinutes == preset.workMinutes &&
        settings.shortMinutes == preset.shortMinutes &&
        settings.longMinutes == preset.longMinutes &&
        settings.sessionsPerCycle == preset.sessionsPerCycle
    }
}

// MARK: - Appearance

private struct AppearanceTab: View {
    @ObservedObject var settings: TimerSettings

    var body: some View {
        Group {
            Section("Window") {
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
            }

            Section("Color") {
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
        }
    }
}

// MARK: - Shortcuts

private struct ShortcutsTab: View {
    @ObservedObject var settings: TimerSettings
    @ObservedObject var hotkeyManager: HotkeyManager

    var body: some View {
        Section("Global hotkeys") {
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
}

// MARK: - Projects

private struct ProjectsTab: View {
    @ObservedObject var projects: FocusProjectLibrary

    var body: some View {
        Section {
            if projects.projects.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "square.stack.3d.up")
                        .font(.system(size: 26, weight: .light))
                        .foregroundStyle(.tertiary)
                    Text("No projects yet")
                        .font(.system(size: 13, weight: .medium))
                    Text("Tag focus blocks with a project to break weekly time down by project.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .listRowBackground(Color.clear)
            } else {
                VStack(spacing: 8) {
                    ForEach(projects.projects) { project in
                        ProjectCard(
                            project: project,
                            onChange: { projects.update($0) },
                            onDelete: { projects.remove(project.id) },
                            onDuplicate: { projects.duplicate(project.id) }
                        )
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
        } header: {
            HStack {
                Text("Projects")
                Spacer()
                Button {
                    _ = projects.add(name: "New project")
                } label: {
                    Label("Add", systemImage: "plus")
                        .labelStyle(.titleAndIcon)
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.borderless)
                .textCase(nil)
            }
        } footer: {
            Text("Archived projects stay in stats but hide from the block picker.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Misc

private struct MiscTab: View {
    @ObservedObject var settings: TimerSettings
    @ObservedObject var library: BreakSuggestionLibrary
    @ObservedObject var calendar: CalendarExporter
    @StateObject private var permissions = NotificationPermissions()

    var body: some View {
        Group {
            Section("Focus guard") {
                Toggle("Pause when I step away", isOn: $settings.idleDetectionEnabled)
                    .toggleStyle(.switch)
                MinuteRow(label: "Away threshold",
                          value: $settings.idleThresholdMinutes,
                          range: 1...30,
                          suffix: "min")
            }

            Section("Calendar export") {
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
                            Spacer()
                            Picker("", selection: $settings.calendarExportIdentifier) {
                                Text("Default").tag("")
                                ForEach(calendar.availableCalendars, id: \.id) { cal in
                                    Text(cal.title).tag(cal.id)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: 220)
                        }
                    }
                }
                if let err = calendar.lastError {
                    Text(err)
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }

            Section("Break suggestions") {
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
                    }
                    Spacer()
                    Button("Reset to defaults") { library.resetToDefaults() }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Sound") {
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

            Section("Permissions") {
                PermissionRow(permissions: permissions, accentColor: settings.accentColor)
            }

            Section {
                MiscFooter()
                    .listRowBackground(Color.clear)
            }
        }
        .onAppear { calendar.refreshAuthState() }
    }
}

private struct MiscFooter: View {
    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "v\(v) (\(b))"
    }
    var body: some View {
        VStack(spacing: 4) {
            Text("Breaks \(versionString)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Made by Gjin Prelvukaj")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

// MARK: - Project Editor Row

struct ProjectCard: View {
    let project: FocusProject
    let onChange: (FocusProject) -> Void
    let onDelete: () -> Void
    let onDuplicate: () -> Void

    @State private var name: String
    @State private var color: Color
    @State private var archived: Bool
    @State private var hovering = false

    init(project: FocusProject,
         onChange: @escaping (FocusProject) -> Void,
         onDelete: @escaping () -> Void,
         onDuplicate: @escaping () -> Void) {
        self.project = project
        self.onChange = onChange
        self.onDelete = onDelete
        self.onDuplicate = onDuplicate
        _name = State(initialValue: project.name)
        _color = State(initialValue: project.color ?? .accentColor)
        _archived = State(initialValue: project.archived)
    }

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 4)
                .padding(.vertical, 6)

            HStack(spacing: 12) {
                ColorPicker("", selection: $color, supportsOpacity: false)
                    .labelsHidden()
                    .onChange(of: color) { _ in commit() }

                TextField("", text: $name, prompt: Text("Untitled project"))
                    .textFieldStyle(.plain)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.primary)
                    .onSubmit { commit() }

                Spacer(minLength: 8)

                if archived {
                    HStack(spacing: 4) {
                        Image(systemName: "archivebox.fill")
                            .font(.system(size: 10))
                        Text("Archived")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(.tertiary)
                }

                Menu {
                    Button {
                        archived.toggle()
                        commit()
                    } label: {
                        Label(archived ? "Unarchive" : "Archive",
                              systemImage: archived ? "tray.and.arrow.up" : "archivebox")
                    }
                    Button {
                        onDuplicate()
                    } label: {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    Divider()
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 24, height: 20)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(hovering ? 0.07 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
        .opacity(archived ? 0.6 : 1)
        .onHover { hovering = $0 }
        .contextMenu {
            Button("Duplicate") { onDuplicate() }
            Button(archived ? "Unarchive" : "Archive") {
                archived.toggle()
                commit()
            }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
        .onChange(of: name) { _ in commit() }
    }

    private func commit() {
        var updated = project
        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? project.name : name
        updated.colorHex = color.toHex()
        updated.archived = archived
        onChange(updated)
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
                .foregroundStyle(accentColor)
                .frame(width: 20)

            TextField("Suggestion", text: $text)
                .textFieldStyle(.plain)
                .onSubmit { commit() }

            TextField("symbol", text: $symbol)
                .textFieldStyle(.plain)
                .font(.caption)
                .frame(width: 90)
                .foregroundStyle(.secondary)
                .onSubmit { commit() }

            Picker("", selection: $applies) {
                ForEach(BreakSuggestion.Applies.allCases) { a in
                    Text(a.label).tag(a)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .frame(width: 90)
            .onChange(of: applies) { _ in commit() }

            Button {
                onDelete()
            } label: {
                Image(systemName: "minus.circle")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
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
