//
//  CalendarExporter.swift
//  Breaks
//
//  Logs completed focus sessions to the user's Calendar via EventKit.
//

import Foundation
import EventKit
import Combine

@MainActor
final class CalendarExporter: ObservableObject {
    enum AuthState: Equatable {
        case unknown
        case denied
        case granted
        case writeOnly
    }

    @Published private(set) var authState: AuthState = .unknown
    @Published private(set) var availableCalendars: [(id: String, title: String)] = []
    @Published private(set) var lastError: String?

    private let store = EKEventStore()

    init() {
        refreshAuthState()
    }

    func refreshAuthState() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized: authState = .granted
        case .fullAccess: authState = .granted
        case .writeOnly: authState = .writeOnly
        case .denied, .restricted: authState = .denied
        case .notDetermined: authState = .unknown
        @unknown default: authState = .unknown
        }
        if authState == .granted || authState == .writeOnly {
            refreshCalendarList()
        }
    }

    func requestAccess() async -> Bool {
        do {
            let granted: Bool
            if #available(macOS 14.0, *) {
                granted = try await store.requestWriteOnlyAccessToEvents()
            } else {
                granted = try await store.requestAccess(to: .event)
            }
            await MainActor.run {
                self.lastError = nil
                self.refreshAuthState()
            }
            return granted
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
                self.refreshAuthState()
            }
            return false
        }
    }

    private func refreshCalendarList() {
        let writable = store.calendars(for: .event).filter { $0.allowsContentModifications }
        availableCalendars = writable.map { ($0.calendarIdentifier, $0.title) }
    }

    /// Writes a completed work session as a calendar event. No-op if disabled,
    /// not authorized, or save fails (error surfaced via `lastError`).
    func exportCompletedSession(title: String,
                                durationMinutes: Int,
                                calendarIdentifier: String?) {
        guard authState == .granted || authState == .writeOnly else { return }
        guard durationMinutes > 0 else { return }

        let end = Date()
        let start = end.addingTimeInterval(TimeInterval(-durationMinutes * 60))

        let calendar: EKCalendar?
        if let id = calendarIdentifier, let found = store.calendar(withIdentifier: id) {
            calendar = found
        } else {
            calendar = store.defaultCalendarForNewEvents
        }
        guard let target = calendar, target.allowsContentModifications else {
            lastError = "No writable calendar available."
            return
        }

        let event = EKEvent(eventStore: store)
        event.title = title.isEmpty ? "Focus session" : title
        event.startDate = start
        event.endDate = end
        event.calendar = target

        do {
            try store.save(event, span: .thisEvent, commit: true)
            lastError = nil
        } catch {
            lastError = error.localizedDescription
        }
    }
}
