//
//  TimerRing.swift
//  Breaks
//
//  Circular progress ring and break suggestion pill.
//

import SwiftUI

// MARK: - Timer Ring

struct TimerRing: View {
    @ObservedObject var timer: BreakTimer
    @ObservedObject var clock: TickClock
    let accentColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.14), lineWidth: 8)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 4) {
                Text(timer.formatted(clock.remaining))
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText(countsDown: true))
                    .animation(.snappy(duration: 0.25), value: clock.remaining)
                Text(timer.isRunning ? "Focus" : "Ready")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(timer.isRunning ? accentColor : .secondary)
                    .textCase(.uppercase)
                    .animation(.easeInOut(duration: 0.3), value: timer.isRunning)
            }
        }
        .frame(width: 144, height: 144)
    }

    private var progress: Double {
        guard timer.duration > 0 else { return 0 }
        return min(1, max(0, 1 - Double(clock.remaining) / Double(timer.duration)))
    }
}

// MARK: - Break Suggestion

struct BreakSuggestionView: View {
    let mode: BreakTimer.Mode
    @ObservedObject var library: BreakSuggestionLibrary
    @State private var seed: Int = Int.random(in: 0..<1000)

    private var current: BreakSuggestion? {
        library.suggestion(for: mode, seed: seed)
    }

    var body: some View {
        Button {
            seed &+= 1
        } label: {
            HStack(spacing: 6) {
                Image(systemName: current?.symbol ?? "sparkles")
                    .font(.caption2)
                Text(current?.text ?? "Take a moment")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.secondary.opacity(0.10))
            )
        }
        .buttonStyle(.plain)
        .help("Click for another suggestion")
        .onChange(of: mode) { _ in
            seed = Int.random(in: 0..<1000)
        }
    }
}
