//
//  FocusAutomationController.swift
//  Breaks
//
//  Runs user-configured Apple Shortcuts when work sessions start/stop.
//  Uses the `shortcuts://run-shortcut` URL scheme so the sandbox does not
//  need extra entitlements. The user must create the named shortcuts in
//  the Shortcuts app — Breaks does not toggle Focus directly.
//

import Foundation
import Combine
import AppKit

@MainActor
final class FocusAutomationController: ObservableObject {
    @Published private(set) var lastError: String?
    private(set) var startedForCurrentSession = false

    func runStart(named name: String) -> Bool {
        let ok = runShortcut(named: name)
        if ok { startedForCurrentSession = true }
        return ok
    }

    func runStopIfStarted(named name: String) {
        guard startedForCurrentSession else { return }
        startedForCurrentSession = false
        _ = runShortcut(named: name)
    }

    func resetSessionFlag() {
        startedForCurrentSession = false
    }

    @discardableResult
    func runShortcut(named name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastError = "Shortcut name is empty."
            return false
        }
        var components = URLComponents()
        components.scheme = "shortcuts"
        components.host = "run-shortcut"
        components.queryItems = [URLQueryItem(name: "name", value: trimmed)]
        guard let url = components.url else {
            lastError = "Could not build shortcuts:// URL."
            return false
        }
        let opened = NSWorkspace.shared.open(url)
        if opened {
            lastError = nil
        } else {
            lastError = "Could not run shortcut “\(trimmed)”. Check Shortcuts app."
        }
        return opened
    }
}
