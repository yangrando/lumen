import Foundation
import Combine

struct XPFloatingReward: Identifiable, Equatable {
    let id: UUID
    let value: Int
    let label: String
}

@MainActor
final class XPTracker: ObservableObject {
    static let shared = XPTracker()

    @Published private(set) var totalXP: Int = 0
    @Published private(set) var floatingRewards: [XPFloatingReward] = []

    private let storagePrefix = "lumen_total_xp_"
    private var loadedUserID: String?

    private init() {}

    func load(for userID: String?) {
        let normalizedUserID = (userID?.isEmpty == false) ? userID : "guest"
        guard loadedUserID != normalizedUserID else { return }
        loadedUserID = normalizedUserID
        totalXP = UserDefaults.standard.integer(forKey: storagePrefix + normalizedUserID!)
    }

    @discardableResult
    func award(for action: ReelLearningAction, userID: String?) -> Int {
        load(for: userID)
        let amount: Int
        switch action {
        case .listen:
            amount = 2
        case .speak:
            amount = 5
        case .askAI:
            amount = 3
        case .translate, .completed:
            amount = 0
        }
        guard amount > 0 else { return 0 }
        totalXP += amount
        if let loadedUserID {
            UserDefaults.standard.set(totalXP, forKey: storagePrefix + loadedUserID)
        }
        let reward = XPFloatingReward(id: UUID(), value: amount, label: "+\(amount) XP")
        floatingRewards.append(reward)
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            await MainActor.run {
                self.floatingRewards.removeAll { $0.id == reward.id }
            }
        }
        return amount
    }
}
