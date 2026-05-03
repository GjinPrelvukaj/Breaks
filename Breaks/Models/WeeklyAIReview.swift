import Foundation
import Combine
#if canImport(FoundationModels)
import FoundationModels
#endif

enum WeeklyAIReviewState: Equatable {
    case idle
    case unsupportedOS
    case modelUnavailable(String)
    case loading
    case loaded(text: String, generatedAt: Date)
    case failed(String)
}

@MainActor
final class WeeklyAIReview: ObservableObject {
    @Published private(set) var state: WeeklyAIReviewState = .idle

    private let ud = UserDefaults.shared
    private let cachePrefix = "aiReview_"
    private var activeTask: Task<Void, Never>?

    init() {
        if let cached = loadCached(forKey: cacheKey(for: Date())) {
            state = .loaded(text: cached.text, generatedAt: cached.generatedAt)
        } else if !isOSSupported {
            state = .unsupportedOS
        }
    }

    private var isOSSupported: Bool {
        if #available(macOS 26.0, *) { return true }
        return false
    }

    func generateIfNeeded(prompt: () -> String) {
        if case .loaded = state { return }
        if case .loading = state { return }
        generate(prompt: prompt())
    }

    func regenerate(prompt: String) {
        activeTask?.cancel()
        clearCache(for: Date())
        generate(prompt: prompt)
    }

    private func generate(prompt: String) {
        guard isOSSupported else {
            state = .unsupportedOS
            return
        }
        #if canImport(FoundationModels)
        if #available(macOS 26.0, *) {
            let model = SystemLanguageModel.default
            switch model.availability {
            case .available:
                break
            case .unavailable(let reason):
                state = .modelUnavailable(describe(reason))
                return
            @unknown default:
                state = .modelUnavailable("Unknown")
                return
            }
            state = .loading
            let weekKey = cacheKey(for: Date())
            activeTask = Task { [weak self] in
                guard let self else { return }
                do {
                    let session = LanguageModelSession(instructions: Self.instructions)
                    let response = try await session.respond(to: prompt)
                    let text = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                    let now = Date()
                    self.saveCached(text: text, generatedAt: now, forKey: weekKey)
                    self.state = .loaded(text: text, generatedAt: now)
                } catch is CancellationError {
                    // swallow
                } catch {
                    self.state = .failed(error.localizedDescription)
                }
            }
        } else {
            state = .unsupportedOS
        }
        #else
        state = .unsupportedOS
        #endif
    }

    @available(macOS 26.0, *)
    private func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible: return "Device does not support Apple Intelligence."
        case .appleIntelligenceNotEnabled: return "Enable Apple Intelligence in System Settings."
        case .modelNotReady: return "Model still downloading. Try again shortly."
        @unknown default: return "Unavailable."
        }
    }

    private static let instructions = """
    You are Breaks AI, a warm and concise focus coach inside the Breaks Pomodoro app, \
    which was created by Gjin Prelvukaj. You are reviewing the user's weekly focus \
    journal. Write a short reflective summary in 3 sentences, then one specific \
    actionable suggestion on a new line prefixed with "Try: ". Avoid corporate jargon. \
    Address the user as "you". Do not invent data not present in the input.
    """

    private struct Cached: Codable {
        let text: String
        let generatedAt: Date
    }

    private func cacheKey(for date: Date) -> String {
        let cal = Calendar(identifier: .iso8601)
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        let y = comps.yearForWeekOfYear ?? 0
        let w = comps.weekOfYear ?? 0
        return "\(cachePrefix)\(y)_W\(w)"
    }

    private func loadCached(forKey key: String) -> Cached? {
        guard let data = ud.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Cached.self, from: data)
    }

    private func saveCached(text: String, generatedAt: Date, forKey key: String) {
        let cached = Cached(text: text, generatedAt: generatedAt)
        if let data = try? JSONEncoder().encode(cached) {
            ud.set(data, forKey: key)
        }
    }

    private func clearCache(for date: Date) {
        ud.removeObject(forKey: cacheKey(for: date))
    }
}
