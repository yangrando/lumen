import Foundation
import Combine

@MainActor
final class ReviewTodayViewModel: ObservableObject {
    @Published private(set) var response: ReviewTodayResponse?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    @Published var feedbackMessage: AppFeedbackMessage?
    @Published private(set) var submittingItemIDs = Set<Int>()
    private var submissionTokensByItemID: [Int: String] = [:]
    private var queuedRefreshTask: Task<Void, Never>?

    func load(accessToken: String) async {
        queuedRefreshTask?.cancel()
        isLoading = true
        errorMessage = nil
        do {
            let loaded = try await ReviewService.shared.fetchToday(accessToken: accessToken)
            response = loaded
            if !loaded.hasItems, (loaded.generatedToday["queued_generation"] ?? 0) > 0 {
                queuedRefreshTask = Task { [weak self] in
                    try? await Task.sleep(nanoseconds: 2_500_000_000)
                    guard !Task.isCancelled else { return }
                    await self?.refreshSilently(accessToken: accessToken)
                }
            }
        } catch {
            response = nil
            errorMessage = UserFacingMessageMapper.localizedErrorMessage(for: error)
        }
        isLoading = false
    }

    func submit(accessToken: String, item: ReviewItem, result: ReviewResultValue) async {
        guard !submittingItemIDs.contains(item.id) else { return }
        submittingItemIDs.insert(item.id)
        defer { submittingItemIDs.remove(item.id) }

        do {
            let token = submissionTokensByItemID[item.id] ?? UUID().uuidString.lowercased()
            submissionTokensByItemID[item.id] = token
            _ = try await ReviewService.shared.submitResult(
                accessToken: accessToken,
                reviewItemID: item.id,
                result: result,
                clientResultID: token
            )
            remove(itemID: item.id)
            submissionTokensByItemID[item.id] = nil
        } catch {
            feedbackMessage = UserFacingMessageMapper.errorFeedback(error)
        }
    }

    func removeItemFromQueue(_ itemID: Int) {
        remove(itemID: itemID)
    }

    private func remove(itemID: Int) {
        guard var response else { return }
        response.groups = response.groups.compactMap { group in
            var copy = group
            copy.items.removeAll { $0.id == itemID }
            return copy.items.isEmpty ? nil : copy
        }
        response = ReviewTodayResponse(
            hasItems: !response.groups.isEmpty,
            totalDueCount: max(response.totalDueCount - 1, 0),
            groups: response.groups,
            generatedToday: response.generatedToday,
            generatedAt: response.generatedAt
        )
        self.response = response
        submissionTokensByItemID[itemID] = nil
    }

    private func refreshSilently(accessToken: String) async {
        do {
            let loaded = try await ReviewService.shared.fetchToday(accessToken: accessToken)
            response = loaded
        } catch {
            // Keep the existing UI state; this is only a best-effort background refresh.
        }
    }
}
