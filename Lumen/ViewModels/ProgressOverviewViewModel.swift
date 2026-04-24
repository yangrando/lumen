import Foundation
import Combine

@MainActor
final class ProgressOverviewViewModel: ObservableObject {
    @Published private(set) var overview: ProgressOverview?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?
    private var lastAccessToken: String?

    func load(accessToken: String) async {
        lastAccessToken = accessToken
        isLoading = true
        errorMessage = nil

        do {
            overview = try await ProgressService.shared.fetchOverview(accessToken: accessToken)
        } catch {
            overview = nil
            errorMessage = UserFacingMessageMapper.localizedErrorMessage(for: error)
        }

        isLoading = false
    }

    func refreshIfPossible() async {
        guard let lastAccessToken else { return }
        do {
            overview = try await ProgressService.shared.fetchOverview(accessToken: lastAccessToken)
            errorMessage = nil
        } catch {
            // Keep the existing UI visible; refresh here is best-effort.
        }
    }
}
