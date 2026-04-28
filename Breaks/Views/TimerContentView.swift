//
//  TimerContentView.swift
//  Breaks
//
//  Main timer page: dashboard, reflection panel, idle prompt, controls.
//

import SwiftUI
import AppKit

// MARK: - Timer View

struct TimerContent: View {
    @ObservedObject var timer: BreakTimer
    @ObservedObject var journal: FocusJournal
    @ObservedObject var settings: TimerSettings
    @Binding var showingSettings: Bool
    @Binding var showingStats: Bool
    @State private var showResetConfirm = false

    var body: some View {
        VStack(spacing: 12) {
            toolbar

            if journal.needsCheckIn {
                MorningCheckIn(journal: journal, accentColor: settings.accentColor)
            } else {
                TodayDashboard(
                    journal: journal,
                    completed: timer.history.totalToday(),
                    accentColor: settings.accentColor,
                    resetToday: { timer.resetToday() }
                )
            }

            if journal.pendingBlock != nil {
                ReflectionPanel(timer: timer, settings: settings, accentColor: settings.accentColor)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if timer.idlePrompt != nil {
                IdlePromptPanel(timer: timer, settings: settings, accentColor: settings.accentColor)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            if timer.history.totalToday() >= journal.dailyGoal {
                DailyRecap(journal: journal, settings: settings, completed: timer.history.totalToday(), accentColor: settings.accentColor)
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }

            TimerRing(timer: timer, clock: timer.clock, accentColor: settings.accentColor)
                .padding(.vertical, 2)

            ModeSegmentedPicker(
                selectedMode: timer.mode,
                durations: BreakTimer.Mode.allCases.map { ($0, settings.minutes(for: $0)) },
                accentColor: settings.accentColor
            ) { mode in
                withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                    timer.setMode(mode)
                }
            }

            if timer.mode != .work {
                BreakSuggestionView(mode: timer.mode)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            controls

            Rectangle()
                .fill(Color.secondary.opacity(0.18))
                .frame(height: 0.5)
                .padding(.top, 2)

            if showResetConfirm {
                HStack(spacing: 8) {
                    Text("Reset today's blocks, focus, and cycle?")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                    Button("Cancel") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            showResetConfirm = false
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    Button("Reset") {
                        timer.resetToday()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            showResetConfirm = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    .tint(.red)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                HStack(spacing: 12) {
                    FooterLink(title: "Reset day", systemImage: "arrow.counterclockwise") {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.85)) {
                            showResetConfirm = true
                        }
                    }
                    Spacer()
                    FooterLink(title: "Quit", systemImage: "power") {
                        NSApp.terminate(nil)
                    }
                    .keyboardShortcut("q")
                }
                .transition(.opacity)
            }
        }
        .padding(14)
        .tint(settings.accentColor)
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: timer.idlePrompt?.id)
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: journal.pendingBlock?.id)
        .animation(.spring(response: 0.34, dampingFraction: 0.84), value: timer.history.totalToday() >= journal.dailyGoal)
        .animation(.easeInOut(duration: 0.25), value: timer.mode)
    }

    private var toolbar: some View {
        HStack {
            Button { showingStats = true } label: {
                Image(systemName: "chart.bar")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(ToolbarIconStyle())
            .help("Statistics")
            Spacer()
            Button { showingSettings = true } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 13, weight: .medium))
            }
            .buttonStyle(ToolbarIconStyle())
            .help("Settings")
            .keyboardShortcut(",", modifiers: [.command])
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            Group {
                if timer.isRunning {
                    Button { timer.pause() } label: {
                        Label("Pause", systemImage: "pause.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .keyboardShortcut(.space, modifiers: [])
                } else {
                    Button { timer.start() } label: {
                        Label(startButtonTitle, systemImage: "play.fill")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .keyboardShortcut(.space, modifiers: [])
                    .disabled(timer.remaining == 0)
                }
            }
            .buttonStyle(HapticPrimaryButtonStyle(tint: settings.accentColor))
            .animation(.spring(response: 0.32, dampingFraction: 0.78), value: timer.isRunning)

            Button { timer.reset() } label: {
                Image(systemName: "arrow.counterclockwise")
            }
            .keyboardShortcut("r", modifiers: [])
            .help("Reset")
            .controlSize(.large)
            .buttonStyle(.bordered)

            Button { timer.skip() } label: {
                Image(systemName: "forward.end.fill")
            }
            .help("Skip phase")
            .controlSize(.large)
            .buttonStyle(.bordered)
        }
        .tint(settings.accentColor)
    }

    private var startButtonTitle: String {
        if journal.needsCheckIn { return "Start my day" }
        if timer.history.totalToday() == 0 { return "Start first block" }
        return "Start next block"
    }
}

// MARK: - Morning Check-In

struct MorningCheckIn: View {
    @ObservedObject var journal: FocusJournal
    let accentColor: Color
    @State private var focusText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Today")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            TextField("What are you focusing on today?", text: $focusText)
                .textFieldStyle(.roundedBorder)
                .onSubmit { startDay() }
            HStack(spacing: 8) {
                Button {
                    startDay()
                } label: {
                    Label("Start my day", systemImage: "sun.max.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(focusText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                if journal.previousFocus != nil {
                    Button("Resume") {
                        journal.continuePreviousFocus()
                    }
                    .buttonStyle(.bordered)
                    .help("Resume yesterday's focus")
                }
            }
            .tint(accentColor)
            if let previousFocus = journal.previousFocus {
                Text("Pick up: \(previousFocus)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .onAppear {
            if focusText.isEmpty {
                focusText = journal.previousFocus ?? ""
            }
        }
    }

    private func startDay() {
        journal.startDay(with: focusText)
    }
}

// MARK: - Today Dashboard

struct TodayDashboard: View {
    @ObservedObject var journal: FocusJournal
    let completed: Int
    let accentColor: Color
    let resetToday: () -> Void
    @State private var expanded = false
    @State private var focusDraft = ""
    @State private var editingToday = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            progressBar
            if expanded {
                expandedControls
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: expanded)
        .animation(.spring(response: 0.32, dampingFraction: 0.82), value: editingToday)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Today")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(journal.primaryFocus.isEmpty ? "Untitled" : journal.primaryFocus)
                    .font(.headline)
                    .lineLimit(1)
                    .foregroundStyle(journal.primaryFocus.isEmpty ? .secondary : .primary)
            }
            Spacer()
            Text("\(min(completed, journal.dailyGoal))/\(journal.dailyGoal)")
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(completed >= journal.dailyGoal ? accentColor : .primary)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: completed)
            Button {
                expanded.toggle()
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(Color.secondary.opacity(expanded ? 0.18 : 0.08))
                    )
            }
            .buttonStyle(.plain)
            .help("More")
        }
    }

    private var progressBar: some View {
        HStack(spacing: 5) {
            ForEach(0..<journal.dailyGoal, id: \.self) { index in
                Capsule()
                    .fill(index < completed ? accentColor : Color.secondary.opacity(0.18))
                    .frame(height: 6)
                    .animation(.spring(response: 0.4, dampingFraction: 0.75).delay(Double(index) * 0.03),
                               value: completed)
            }
        }
    }

    @ViewBuilder
    private var expandedControls: some View {
        VStack(alignment: .leading, spacing: 8) {
            if editingToday {
                HStack(spacing: 6) {
                    TextField("Today focus", text: $focusDraft)
                        .textFieldStyle(.roundedBorder)
                    Button("Save") {
                        journal.setPrimaryFocus(focusDraft)
                        editingToday = false
                    }
                    .buttonStyle(.borderedProminent)
                    Button {
                        editingToday = false
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.bordered)
                    .help("Cancel")
                }
                .controlSize(.small)
                .tint(accentColor)
            }

            HStack {
                Text("Goal")
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(journal.dailyGoal) blocks")
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                Stepper("", value: $journal.dailyGoal, in: 1...12)
                    .labelsHidden()
            }
            .font(.caption)

            TextField("This block is for…", text: $journal.currentBlockLabel)
                .textFieldStyle(.roundedBorder)
                .controlSize(.small)

            HStack {
                Button {
                    focusDraft = journal.primaryFocus
                    editingToday = true
                } label: {
                    Label("Edit focus", systemImage: "pencil")
                }
                Spacer()
                Button(role: .destructive) {
                    resetToday()
                } label: {
                    Label("Reset day", systemImage: "arrow.counterclockwise")
                }
            }
            .buttonStyle(.plain)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.top, 2)
    }
}

// MARK: - Reflection Panel

struct ReflectionPanel: View {
    @ObservedObject var timer: BreakTimer
    @ObservedObject var settings: TimerSettings
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("How was that block?")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            HStack(spacing: 6) {
                outcomeButton(.good)
                outcomeButton(.messy)
                Button {
                    timer.resolvePendingBlock(as: .skipped)
                } label: {
                    Label("Skip", systemImage: FocusOutcome.skipped.systemImage)
                        .labelStyle(.iconOnly)
                        .frame(maxWidth: .infinity)
                }
                .help("Skip logging")
            }
            .buttonStyle(.bordered)
            .tint(accentColor)
        }
        .padding(10)
        .glassCard(tint: accentColor)
    }

    private func outcomeButton(_ outcome: FocusOutcome) -> some View {
        Button {
            timer.resolvePendingBlock(as: outcome)
        } label: {
            Label(outcome.rawValue, systemImage: outcome.systemImage)
                .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Idle Prompt Panel

struct IdlePromptPanel: View {
    @ObservedObject var timer: BreakTimer
    @ObservedObject var settings: TimerSettings
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz.fill")
                    .foregroundStyle(accentColor)
                Text("Paused while away")
                    .font(.caption.weight(.semibold))
                Spacer()
                if let idlePrompt = timer.idlePrompt {
                    Text("\(Int(idlePrompt.idleSeconds / 60))m away")
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            Text("Time restored. Resume when you're ready.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                Button {
                    timer.resumeAfterIdle()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                Button {
                    timer.resetAfterIdle()
                } label: {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                        .labelStyle(.iconOnly)
                        .frame(width: 38)
                }
                .help("Reset this block")
            }
            .buttonStyle(.bordered)
            .tint(accentColor)
        }
        .padding(10)
        .glassCard()
    }
}

// MARK: - Daily Recap

struct DailyRecap: View {
    @ObservedObject var journal: FocusJournal
    @ObservedObject var settings: TimerSettings
    let completed: Int
    let accentColor: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text("Daily goal hit")
                    .font(.caption.weight(.semibold))
                Text("\(completed) blocks, \(journal.focusedMinutesToday())m focused")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(9)
        .glassCard()
    }
}
