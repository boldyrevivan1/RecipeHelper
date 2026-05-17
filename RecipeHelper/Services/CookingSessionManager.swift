import Foundation
import SwiftUI

struct ActiveCookingSession: Identifiable {
    let id          = UUID()
    let recipeId:   UUID
    let recipeTitle: String
    let imageURL:   String?
    let totalSeconds: Int
    var remainingSeconds: Int
    var isRunning:  Bool = false
    var startedAt:  Date = Date()
    var backgroundedAt: Date? = nil

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(totalSeconds - remainingSeconds) / Double(totalSeconds)
    }

    var timeString: String {
        let m = remainingSeconds / 60
        let s = remainingSeconds % 60
        return String(format: "%02d:%02d", m, s)
    }

    var isFinished: Bool { remainingSeconds <= 0 }
}

@MainActor
class CookingSessionManager: ObservableObject {
    static let shared = CookingSessionManager()

    @Published var sessions: [ActiveCookingSession] = []
    @Published var selectedSessionId: UUID? = nil

    private var timers: [UUID: Timer] = [:]
    private init() {}

    func startSession(recipe: Recipe) -> ActiveCookingSession {

        if let existing = sessions.first(where: { $0.recipeId == recipe.id }) {
            return existing
        }
        let session = ActiveCookingSession(
            recipeId:       recipe.id,
            recipeTitle:    recipe.title,
            imageURL:       recipe.imageURL,
            totalSeconds:   recipe.preparationTime * 60,
            remainingSeconds: recipe.preparationTime * 60
        )
        sessions.append(session)
        return session
    }

    func startTimer(for sessionId: UUID) {
        guard let idx = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        sessions[idx].isRunning = true

        let t = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                guard let i = self.sessions.firstIndex(where: { $0.id == sessionId }) else { return }
                if self.sessions[i].remainingSeconds > 0 {
                    self.sessions[i].remainingSeconds -= 1
                } else {
                    self.sessions[i].isRunning = false
                    self.timers[sessionId]?.invalidate()
                    self.timers[sessionId] = nil
                }
            }
        }
        timers[sessionId] = t
    }

    func pauseTimer(for sessionId: UUID) {
        guard let idx = sessions.firstIndex(where: { $0.id == sessionId }) else { return }
        sessions[idx].isRunning = false
        timers[sessionId]?.invalidate()
        timers[sessionId] = nil
    }

    func removeSession(_ sessionId: UUID) {
        timers[sessionId]?.invalidate()
        timers[sessionId] = nil
        sessions.removeAll { $0.id == sessionId }
    }

    func session(for id: UUID) -> ActiveCookingSession? {
        sessions.first { $0.id == id }
    }

    func appDidBackground() {
        for i in sessions.indices where sessions[i].isRunning {
            sessions[i].backgroundedAt = Date()
        }
    }

    func appDidForeground() {

        let now = Date()
        for i in sessions.indices {
            guard sessions[i].isRunning,
                  let bg = sessions[i].backgroundedAt else { continue }
            let elapsed = Int(now.timeIntervalSince(bg))
            sessions[i].remainingSeconds = max(0, sessions[i].remainingSeconds - elapsed)
            sessions[i].backgroundedAt = nil
            if sessions[i].remainingSeconds == 0 {
                sessions[i].isRunning = false
                timers[sessions[i].id]?.invalidate()
                timers[sessions[i].id] = nil
            }
        }
    }
}
