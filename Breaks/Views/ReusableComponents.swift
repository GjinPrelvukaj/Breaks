//
//  ReusableComponents.swift
//  Breaks
//
//  Shared UI components used across multiple views.
//

import SwiftUI

// MARK: - Preset Button

struct PresetButton: View {
    let title: String
    let subtitle: String
    let selected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(title).font(.system(.body, design: .rounded).weight(.semibold))
                Text(subtitle).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(selected ? accentColor : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Footer Link

struct FooterLink: View {
    let title: String
    let systemImage: String
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 9, weight: .medium))
                Text(title)
                    .font(.caption2)
            }
            .foregroundStyle(hovering ? .primary : .secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(Color.secondary.opacity(hovering ? 0.10 : 0))
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.15), value: hovering)
    }
}

// MARK: - Mode Segmented Picker

struct ModeSegmentedPicker: View {
    let selectedMode: BreakTimer.Mode
    let durations: [(BreakTimer.Mode, Int)]
    let accentColor: Color
    let action: (BreakTimer.Mode) -> Void
    @Namespace private var pillNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(durations, id: \.0) { entry in
                let mode = entry.0
                let minutes = entry.1
                let selected = mode == selectedMode
                Button {
                    action(mode)
                } label: {
                    VStack(spacing: 1) {
                        Text(mode.shortLabel)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(selected ? .primary : .secondary)
                        Text("\(minutes)m")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(selected ? accentColor : .secondary.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background {
                        if selected {
                            RoundedRectangle(cornerRadius: 7, style: .continuous)
                                .fill(.background)
                                .shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                                .matchedGeometryEffect(id: "selection", in: pillNamespace)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.secondary.opacity(0.10))
        )
    }
}

// MARK: - Duration Preset Button

struct DurationPresetButton: View {
    let preset: DurationPreset
    let selected: Bool
    let accentColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(preset.title)
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text("\(preset.workMinutes)/\(preset.shortMinutes)/\(preset.longMinutes)")
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, minHeight: 38)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(selected ? accentColor.opacity(0.18) : Color.secondary.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(selected ? accentColor : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("\(preset.workMinutes)m work, \(preset.shortMinutes)m short, \(preset.longMinutes)m long")
    }
}

// MARK: - Hotkey Editor Row

struct HotkeyEditorRow: View {
    let action: HotkeyAction
    @Binding var keyCode: Int
    @Binding var modifiers: Int

    var body: some View {
        HStack(spacing: 8) {
            Label(action.title, systemImage: action.systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
            Picker("", selection: $modifiers) {
                ForEach(HotkeyModifierOption.all) { option in
                    Text(option.label).tag(option.modifiers)
                }
            }
            .labelsHidden()
            .frame(width: 74)
            Picker("", selection: $keyCode) {
                ForEach(HotkeyKeyOption.all) { option in
                    Text(option.label).tag(option.keyCode)
                }
            }
            .labelsHidden()
            .frame(width: 82)
        }
    }
}

// MARK: - App Info Footer

struct AppInfoFooter: View {
    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Breaks")
                        .font(.caption.weight(.semibold))
                    Text("Version \(version)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("Made by Gjin")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                Link(destination: URL(string: "https://www.gjinprelvukaj.com")!) {
                    Label("Portfolio", systemImage: "globe")
                        .font(.caption2)
                }
                Link(destination: URL(string: "https://github.com/gjinprelvukaj")!) {
                    Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.caption2)
                }
                Spacer()
            }
            .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Minute Row

struct MinuteRow: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var suffix: String = "min"

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(display)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Stepper("", value: $value, in: range)
                .labelsHidden()
        }
    }

    private var display: String {
        suffix.isEmpty ? "\(value)" : "\(value) \(suffix)"
    }
}
