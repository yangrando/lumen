import Foundation
import Combine

enum ReelLearningAction: String, Codable, CaseIterable {
    case listen
    case speak
    case askAI = "ask_ai"
    case translate
    case completed
}

struct ReelLearningState: Codable, Equatable {
    var completedActions: Set<ReelLearningAction> = []

    static let totalSteps = 5

    var isCompleted: Bool {
        completedActions.contains(.completed)
    }

    var progressCount: Int {
        completedActions.count
    }

    mutating func mark(_ action: ReelLearningAction) {
        completedActions.insert(action)
        if completedActions.contains(.listen), completedActions.contains(.speak), completedActions.contains(.askAI) {
            completedActions.insert(.completed)
        }
    }
}

@MainActor
final class ReelInteractionService: ObservableObject {
    static let shared = ReelInteractionService()

    @Published private(set) var statesByReelID: [String: ReelLearningState] = [:]

    private let storagePrefix = "lumen_reel_learning_state_"
    private var loadedUserID: String?

    private init() {}

    func load(for userID: String?) {
        let normalizedUserID = (userID?.isEmpty == false) ? userID : "guest"
        guard loadedUserID != normalizedUserID else { return }
        loadedUserID = normalizedUserID
        guard let data = UserDefaults.standard.data(forKey: storagePrefix + normalizedUserID!) else {
            statesByReelID = [:]
            return
        }
        statesByReelID = (try? JSONDecoder().decode([String: ReelLearningState].self, from: data)) ?? [:]
    }

    func state(for reelID: String) -> ReelLearningState {
        statesByReelID[reelID] ?? ReelLearningState()
    }

    @discardableResult
    func register(_ action: ReelLearningAction, for reelID: String, userID: String?) -> (state: ReelLearningState, wasNew: Bool, completedNow: Bool) {
        load(for: userID)
        var state = statesByReelID[reelID] ?? ReelLearningState()
        let previous = state
        let wasCompleted = previous.isCompleted
        state.mark(action)
        statesByReelID[reelID] = state
        persist()
        return (state, !previous.completedActions.contains(action), !wasCompleted && state.isCompleted)
    }

    private func persist() {
        guard let loadedUserID else { return }
        guard let data = try? JSONEncoder().encode(statesByReelID) else { return }
        UserDefaults.standard.set(data, forKey: storagePrefix + loadedUserID)
    }
}
