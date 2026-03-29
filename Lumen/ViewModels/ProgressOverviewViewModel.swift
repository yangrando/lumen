import Foundation
import Combine

@MainActor
final class ProgressOverviewViewModel: ObservableObject {
    @Published private(set) var overview: ProgressOverview?
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    func load(accessToken: String) async {
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
}
