//
//  BreakSuggestionLibrary.swift
//  Breaks
//
//  User-editable library of break suggestions shown during short and long breaks.
//

import SwiftUI
import Combine

struct BreakSuggestion: Identifiable, Codable, Equatable {
    enum Applies: String, Codable, CaseIterable, Identifiable {
        case short, long, any
        var id: String { rawValue }
        var label: String {
            switch self {
            case .short: return "Short"
            case .long: return "Long"
            case .any: return "Any"
            }
        }
    }

    var id: UUID
    var text: String
    var symbol: String
    var applies: Applies

    init(id: UUID = UUID(), text: String, symbol: String, applies: Applies) {
        self.id = id
        self.text = text
        self.symbol = symbol
        self.applies = applies
    }

    func matches(_ mode: BreakTimer.Mode) -> Bool {
        switch applies {
        case .any: return mode != .work
        case .short: return mode == .shortBreak
        case .long: return mode == .longBreak
        }
    }
}

@MainActor
final class BreakSuggestionLibrary: ObservableObject {
    static let storageKey = "breakSuggestionsLibrary"

    static let defaults: [BreakSuggestion] = [
        BreakSuggestion(text: "Look away, breathe, reset", symbol: "eye", applies: .short),
        BreakSuggestion(text: "Roll shoulders, unclench jaw", symbol: "figure.flexibility", applies: .short),
        BreakSuggestion(text: "Sip water, blink slowly", symbol: "drop", applies: .short),
        BreakSuggestion(text: "Stand up, water, recover", symbol: "figure.walk", applies: .long),
        BreakSuggestion(text: "Walk around, look outside", symbol: "leaf", applies: .long),
        BreakSuggestion(text: "Stretch back and hips", symbol: "figure.cooldown", applies: .long)
    ]

    @Published var suggestions: [BreakSuggestion] {
        didSet { save() }
    }

    private let ud = UserDefaults.shared

    init() {
        if let data = ud.data(forKey: Self.storageKey),
           let decoded = try? JSONDecoder().decode([BreakSuggestion].self, from: data) {
            self.suggestions = decoded
        } else {
            self.suggestions = Self.defaults
        }
    }

    func suggestion(for mode: BreakTimer.Mode, seed: Int = 0) -> BreakSuggestion? {
        let pool = suggestions.filter { $0.matches(mode) }
        guard !pool.isEmpty else {
            return suggestions.first { $0.applies == .any && mode != .work }
                ?? Self.defaults.first { $0.matches(mode) }
        }
        return pool[abs(seed) % pool.count]
    }

    func add(_ s: BreakSuggestion) {
        suggestions.append(s)
    }

    func remove(_ id: UUID) {
        suggestions.removeAll { $0.id == id }
    }

    func update(_ s: BreakSuggestion) {
        guard let i = suggestions.firstIndex(where: { $0.id == s.id }) else { return }
        suggestions[i] = s
    }

    func resetToDefaults() {
        suggestions = Self.defaults
    }

    private func save() {
        if let data = try? JSONEncoder().encode(suggestions) {
            ud.set(data, forKey: Self.storageKey)
        }
    }
}
