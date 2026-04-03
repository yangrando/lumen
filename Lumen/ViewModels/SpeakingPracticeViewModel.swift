import Foundation
import Combine

@MainActor
final class SpeakingPracticeViewModel: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var isUploading = false
    @Published private(set) var elapsedSeconds: TimeInterval = 0
    @Published private(set) var attempt: SpeakingAttempt?
    @Published var errorMessage: String?

    let recordingService = AudioRecordingService()

    private let accessToken: String
    private let targetText: String
    private let reelID: String?
    private let reviewItemID: Int?
    private var cancellables = Set<AnyCancellable>()
    private var latestRecordedFileURL: URL?
    private var currentAttemptID = UUID().uuidString.lowercased()

    init(accessToken: String, targetText: String, reelID: String?, reviewItemID: Int?) {
        self.accessToken = accessToken
        self.targetText = targetText
        self.reelID = reelID
        self.reviewItemID = reviewItemID

        recordingService.$isRecording
            .assign(to: &$isRecording)

        recordingService.$elapsedSeconds
            .assign(to: &$elapsedSeconds)

        recordingService.$errorMessage
            .sink { [weak self] message in
                guard let self, let message, !message.isEmpty else { return }
                self.errorMessage = message
            }
            .store(in: &cancellables)
    }

    func startRecording() async {
        guard !isUploading else { return }
        errorMessage = nil
        attempt = nil
        currentAttemptID = UUID().uuidString.lowercased()
        _ = await recordingService.startRecording()
    }

    func stopAndSubmit() async -> SpeakingAttempt? {
        guard !isUploading else { return nil }
        errorMessage = nil

        guard let fileURL = await recordingService.stopRecording() else {
            errorMessage = LocalizedStrings.speakingRecordBeforeSubmit
            return nil
        }

        latestRecordedFileURL = fileURL

        if elapsedSeconds < 0.5 {
            errorMessage = LocalizedStrings.speakingRecordingTooShort
            return nil
        }

        isUploading = true
        defer { isUploading = false }

        do {
            let response = try await SpeakingPracticeService.shared.analyze(
                accessToken: accessToken,
                audioFileURL: fileURL,
                mode: .repeatExactly,
                targetText: targetText,
                reelID: reelID,
                reviewItemID: reviewItemID,
                durationSeconds: elapsedSeconds,
                clientAttemptID: currentAttemptID
            )
            attempt = response
            return response
        } catch {
            if let urlError = error as? URLError, urlError.code == .timedOut {
                errorMessage = LocalizedStrings.speakingRequestTimedOut
            } else {
                errorMessage = UserFacingMessageMapper.localizedErrorMessage(for: error)
            }
            return nil
        }
    }

    func retry() {
        errorMessage = nil
        attempt = nil
        elapsedSeconds = 0
        currentAttemptID = UUID().uuidString.lowercased()
        if let latestRecordedFileURL {
            try? FileManager.default.removeItem(at: latestRecordedFileURL)
        }
        latestRecordedFileURL = nil
    }

    func cancelRecording() {
        recordingService.cancelRecording()
        errorMessage = nil
    }
}
