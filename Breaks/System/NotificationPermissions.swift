import SwiftUI
import Combine
import UserNotifications
import AppKit

@MainActor
final class NotificationPermissions: ObservableObject {
    enum Status {
        case notDetermined, denied, authorized, provisional
        var label: String {
            switch self {
            case .notDetermined: return "Not set"
            case .denied: return "Off"
            case .authorized: return "On"
            case .provisional: return "Quiet"
            }
        }
        var systemImage: String {
            switch self {
            case .authorized, .provisional: return "checkmark.circle.fill"
            case .denied: return "xmark.circle.fill"
            case .notDetermined: return "questionmark.circle.fill"
            }
        }
    }

    @Published private(set) var status: Status = .notDetermined

    init() {
        Task { await refresh() }
    }

    func refresh() async {
        let s = await UNUserNotificationCenter.current().notificationSettings()
        switch s.authorizationStatus {
        case .notDetermined: status = .notDetermined
        case .denied: status = .denied
        case .authorized: status = .authorized
        case .provisional, .ephemeral: status = .provisional
        @unknown default: status = .notDetermined
        }
    }

    func request() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])
        await refresh()
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Notifications-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }
}
