//
//  BreaksApp.swift
//  Breaks
//
//  Pomodoro timer with session history, global hotkeys, persistent state, and more.
//  Made by Gjin Prelvukaj
//

import SwiftUI
import AppKit
import UserNotifications

@main
struct BreaksApp: App {
    @NSApplicationDelegateAdaptor(BreaksAppDelegate.self) private var appDelegate
    @StateObject private var timer = BreakTimer()
    @StateObject private var hotkeyManager = HotkeyManager()

    var body: some Scene {
        MenuBarExtra {
            TimerPopover(timer: timer, settings: timer.settings, hotkeyManager: hotkeyManager)
                .tint(timer.settings.accentColor)
        } label: {
            MenuBarLabel(timer: timer, clock: timer.clock)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsWindow(timer: timer, hotkeyManager: hotkeyManager)
                .tint(timer.settings.accentColor)
        }
    }
}

enum SettingsWindowOpener {
    static func open() {
        NSApp.activate(ignoringOtherApps: true)
        if NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) { return }
        NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
    }
}

struct MenuBarLabel: View {
    @ObservedObject var timer: BreakTimer
    @ObservedObject var clock: TickClock

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: timer.menuIcon)
            if !timer.flowMode, let title = timer.menuBarTitle(for: clock.remaining) {
                Text(title).monospacedDigit()
            }
        }
    }
}

final class BreaksAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        let me = Bundle.main.bundleIdentifier ?? "com.gjinprelvukaj.Breaks"
        let myPID = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication.runningApplications(withBundleIdentifier: me)
            .filter { $0.processIdentifier != myPID }
        if let existing = others.first {
            existing.activate(options: [.activateIgnoringOtherApps])
            exit(0)
        }

        UNUserNotificationCenter.current().delegate = self
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        openMenuBarPopover()
        return false
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // If the user is already looking at the popover, the timer is right
        // there — no need to show a banner or play a sound on top of it.
        Task { @MainActor in
            if PopoverPresence.isOpen {
                completionHandler([])
            } else {
                completionHandler([.banner, .sound])
            }
        }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier {
            DispatchQueue.main.async { [weak self] in
                self?.openMenuBarPopover()
            }
        }
        completionHandler()
    }

    private func openMenuBarPopover() {
        NSApp.activate(ignoringOtherApps: true)
        guard let button = NSApp.windows.lazy
            .compactMap({ Self.findStatusBarButton(in: $0.contentView) })
            .first else { return }
        if button.window?.isVisible == true && button.state == .on { return }
        button.performClick(nil)
    }

    private static func findStatusBarButton(in view: NSView?) -> NSStatusBarButton? {
        guard let view else { return nil }
        if let btn = view as? NSStatusBarButton { return btn }
        for sub in view.subviews {
            if let found = findStatusBarButton(in: sub) { return found }
        }
        return nil
    }
}
