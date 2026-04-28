//
//  OnboardingView.swift
//  Breaks
//
//  Three-step onboarding: welcome, rhythm, permissions.
//

import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settings: TimerSettings
    @ObservedObject var journal: FocusJournal
    @StateObject private var permissions = NotificationPermissions()
    @State private var focusText = ""
    @State private var step: Step = .welcome

    enum Step: Int, CaseIterable { case welcome, rhythm, permissions }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

            ZStack {
                switch step {
                case .welcome:
                    welcomeStep
                        .transition(stepTransition(forward: false))
                case .rhythm:
                    rhythmStep
                        .transition(stepTransition(forward: true))
                case .permissions:
                    permissionsStep
                        .transition(stepTransition(forward: true))
                }
            }
            .animation(.spring(response: 0.36, dampingFraction: 0.85), value: step)

            Spacer(minLength: 4)

            footer
        }
        .padding(16)
        .frame(minHeight: 420)
        .onAppear {
            focusText = journal.previousFocus ?? journal.primaryFocus
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "timer")
                .foregroundStyle(settings.accentColor)
                .font(.system(size: 16, weight: .semibold))
            Text("Breaks")
                .font(.headline)
            Spacer()
            HStack(spacing: 5) {
                ForEach(Step.allCases, id: \.rawValue) { s in
                    Capsule()
                        .fill(s == step ? settings.accentColor : Color.secondary.opacity(0.25))
                        .frame(width: s == step ? 16 : 6, height: 6)
                        .animation(.spring(response: 0.32, dampingFraction: 0.8), value: step)
                }
            }
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome")
                    .font(.title3.weight(.semibold))
                Text("A pomodoro timer that doesn't punish you. Miss a day, lose one. Not all of it.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                onboardingFeature(icon: "flame.fill",
                                  title: "Streak that decays, not resets",
                                  body: "Miss a day → −1. Rest days never decay.")
                onboardingFeature(icon: "menubar.rectangle",
                                  title: "Lives in your menu bar",
                                  body: "Reopen via Spotlight or Applications anytime.")
                onboardingFeature(icon: "command",
                                  title: "Global hotkeys",
                                  body: "⌘⌥B start/pause from anywhere.")
            }
        }
    }

    private var rhythmStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Today's focus")
                    .font(.title3.weight(.semibold))
                TextField("What are you working on?", text: $focusText)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Daily rhythm")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                HStack {
                    Text("Goal")
                    Spacer()
                    Text("\(journal.dailyGoal) blocks")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Stepper("", value: $journal.dailyGoal, in: 1...12)
                        .labelsHidden()
                }
                HStack {
                    Text("Rest days / week")
                    Spacer()
                    Text("\(settings.pauseDaysPerWeek)")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    Stepper("", value: $settings.pauseDaysPerWeek, in: 0...3)
                        .labelsHidden()
                }
                Toggle("Pause if I step away", isOn: $settings.idleDetectionEnabled)
                    .toggleStyle(.switch)
                Toggle("Start at login", isOn: Binding(
                    get: { settings.launchAtLogin },
                    set: { settings.setLaunchAtLogin($0) }
                ))
                .toggleStyle(.switch)
            }
        }
    }

    private var permissionsStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("One last thing")
                    .font(.title3.weight(.semibold))
                Text("Notifications let Breaks tell you when a block ends, even if the popover is closed.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            PermissionRow(permissions: permissions, accentColor: settings.accentColor)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundStyle(settings.accentColor)
                    .font(.caption)
                Text("You can change these anytime in Settings.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(settings.accentColor.opacity(0.10))
            )
        }
    }

    private var footer: some View {
        HStack(spacing: 8) {
            if step != .welcome {
                Button {
                    advance(by: -1)
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .tint(.secondary)
            }

            if step == .permissions {
                Button {
                    finish()
                } label: {
                    Label("Open Breaks", systemImage: "arrow.right.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(settings.accentColor)
            } else {
                Button {
                    advance(by: 1)
                } label: {
                    Label("Continue", systemImage: "chevron.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(settings.accentColor)
            }
        }

        // Skip in a row below for tertiary action
    }

    @ViewBuilder
    private func onboardingFeature(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(settings.accentColor)
                .frame(width: 22)
                .font(.system(size: 14, weight: .medium))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.callout.weight(.medium))
                Text(body)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }

    private func stepTransition(forward: Bool) -> AnyTransition {
        let edge: Edge = forward ? .trailing : .leading
        return .asymmetric(
            insertion: .move(edge: edge).combined(with: .opacity),
            removal: .move(edge: edge == .trailing ? .leading : .trailing).combined(with: .opacity)
        )
    }

    private func advance(by delta: Int) {
        let next = max(0, min(Step.allCases.count - 1, step.rawValue + delta))
        if let s = Step(rawValue: next) { step = s }
    }

    private func finish() {
        if let focus = focusText.nilIfBlank {
            journal.startDay(with: focus)
        }
        settings.completeOnboarding()
    }
}

// MARK: - Permission Row

struct PermissionRow: View {
    @ObservedObject var permissions: NotificationPermissions
    let accentColor: Color
    @State private var requesting = false

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "bell.fill")
                .foregroundStyle(accentColor)
                .frame(width: 18)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("Notifications")
                        .font(.caption.weight(.medium))
                    Image(systemName: permissions.status.systemImage)
                        .font(.caption2)
                        .foregroundStyle(statusColor)
                    Text(permissions.status.label)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            actionButton
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
        .task { await permissions.refresh() }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch permissions.status {
        case .notDetermined:
            Button {
                requesting = true
                Task {
                    await permissions.request()
                    requesting = false
                }
            } label: {
                Text(requesting ? "…" : "Enable")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .tint(accentColor)
            .disabled(requesting)
        case .denied:
            Button("Open Settings") {
                permissions.openSystemSettings()
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        case .authorized, .provisional:
            EmptyView()
        }
    }

    private var subtitle: String {
        switch permissions.status {
        case .authorized: return "You'll be alerted when each block ends."
        case .provisional: return "Quiet delivery enabled."
        case .denied: return "Enable in System Settings to get end-of-block alerts."
        case .notDetermined: return "Get a heads-up when each focus block ends."
        }
    }

    private var statusColor: Color {
        switch permissions.status {
        case .authorized, .provisional: return .green
        case .denied: return .orange
        case .notDetermined: return .secondary
        }
    }
}
