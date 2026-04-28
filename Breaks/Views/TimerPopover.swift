//
//  TimerPopover.swift
//  Breaks
//
//  Root popover view — routes between onboarding, stats, settings, and timer.
//

import SwiftUI

struct TimerPopover: View {
    @ObservedObject var timer: BreakTimer
    @ObservedObject var settings: TimerSettings
    @ObservedObject var hotkeyManager: HotkeyManager
    @State private var showingSettings = false
    @State private var showingStats = false

    private enum Page: Hashable { case onboarding, stats, settings, timer }
    private var currentPage: Page {
        if !settings.hasCompletedOnboarding { return .onboarding }
        if showingStats { return .stats }
        if showingSettings { return .settings }
        return .timer
    }

    var body: some View {
        ZStack {
            switch currentPage {
            case .onboarding:
                OnboardingView(settings: settings, journal: timer.journal)
                    .transition(pageTransition(forward: true))
            case .stats:
                StatsView(history: timer.history, journal: timer.journal, settings: settings, showing: $showingStats)
                    .transition(pageTransition(forward: false))
            case .settings:
                SettingsPanel(settings: settings, hotkeyManager: hotkeyManager, showing: $showingSettings)
                    .transition(pageTransition(forward: true))
            case .timer:
                TimerContent(timer: timer,
                             journal: timer.journal,
                             settings: settings,
                             showingSettings: $showingSettings,
                             showingStats: $showingStats)
                    .transition(pageTransition(forward: false))
            }
        }
        .animation(.spring(response: 0.36, dampingFraction: 0.84), value: currentPage)
        .frame(width: 320)
        .background(Color.clear)
        .onAppear {
            hotkeyManager.setHandler(for: 1) {
                timer.isRunning ? timer.pause() : timer.start()
            }
            hotkeyManager.setHandler(for: 2) { timer.skip() }
            hotkeyManager.setHandler(for: 3) { timer.resetCycle() }
            hotkeyManager.reloadHotkeys(settings: settings)
        }
    }

    private func pageTransition(forward: Bool) -> AnyTransition {
        let edge: Edge = forward ? .trailing : .leading
        return .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: edge == .trailing ? .leading : .trailing).combined(with: .opacity)
        )
    }
}
