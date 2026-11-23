import Foundation
import Combine

enum AnalysisPhase: Equatable {
    case idle
    case uploading   // audio bytes in transit
    case analyzing   // server transcribing + scoring
    case retrying    // first attempt timed out, retrying automatically
}

@MainActor
final class SpeakingPracticeViewModel: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var isUploading = false
    @Published private(set) var analysisPhase: AnalysisPhase = .idle
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
    private var analysisTask: Task<SpeakingAttempt, Error>?
    private var phaseTask: Task<Void, Never>?

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
        cancelPendingAnalysis()
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
        analysisPhase = .uploading
        let submittedAttemptID = currentAttemptID

        // Switch phase label after estimated upload window (5 s).
        // Files are now ~70 % smaller (16 kHz/32 kbps), so upload is fast;
        // remaining wait is server transcription + scoring.
        phaseTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(5))
            guard let self, self.isUploading else { return }
            self.analysisPhase = .analyzing
        }

        do {
            let response = try await runAnalysisWithRetry(
                fileURL: fileURL,
                attemptID: submittedAttemptID
            )
            finishUploading()
            attempt = response
            NotificationCenter.default.post(name: .progressOverviewShouldRefresh, object: nil)
            return response
        } catch is CancellationError {
            if analysisTask?.isCancelled == true {
                finishUploading()
                return nil
            }
            finishUploading()
            errorMessage = LocalizedStrings.speakingRequestTimedOut
            return nil
        } catch {
            finishUploading()
            if let urlError = error as? URLError, urlError.code == .timedOut {
                errorMessage = LocalizedStrings.speakingRequestTimedOut
            } else {
                errorMessage = UserFacingMessageMapper.localizedErrorMessage(for: error)
            }
            return nil
        }
    }

    func retry() {
        cancelPendingAnalysis()
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
        cancelPendingAnalysis()
        recordingService.cancelRecording()
        errorMessage = nil
    }

    // MARK: - Private

    /// Runs the analysis request and retries once automatically if the server times out.
    /// The second attempt uses a fresh `clientAttemptID` and waits 3 s so the server
    /// can shed load before retrying.
    private func runAnalysisWithRetry(fileURL: URL, attemptID: String) async throws -> SpeakingAttempt {
        do {
            let task = Task {
                try await SpeakingPracticeService.shared.analyze(
                    accessToken: accessToken,
                    audioFileURL: fileURL,
                    mode: .repeatExactly,
                    targetText: targetText,
                    reelID: reelID,
                    reviewItemID: reviewItemID,
                    durationSeconds: elapsedSeconds,
                    clientAttemptID: attemptID
                )
            }
            analysisTask = task
            return try await task.value
        } catch let error as URLError where error.code == .timedOut {
            // First attempt timed out — wait 3 s and retry once automatically
            analysisTask = nil
            analysisPhase = .retrying
            phaseTask?.cancel()

            try await Task.sleep(for: .seconds(3))

            // Guard: user may have cancelled during the sleep
            guard isUploading else { throw CancellationError() }

            analysisPhase = .uploading
            let retryAttemptID = UUID().uuidString.lowercased()

            // Restart the phase timer for the retry
            phaseTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(5))
                guard let self, self.isUploading else { return }
                self.analysisPhase = .analyzing
            }

            let retryTask = Task {
                try await SpeakingPracticeService.shared.analyze(
                    accessToken: accessToken,
                    audioFileURL: fileURL,
                    mode: .repeatExactly,
                    targetText: targetText,
                    reelID: reelID,
                    reviewItemID: reviewItemID,
                    durationSeconds: elapsedSeconds,
                    clientAttemptID: retryAttemptID
                )
            }
            analysisTask = retryTask
            return try await retryTask.value
        }
    }

    private func finishUploading() {
        phaseTask?.cancel()
        phaseTask = nil
        analysisTask = nil
        isUploading = false
        analysisPhase = .idle
    }

    private func cancelPendingAnalysis() {
        phaseTask?.cancel()
        phaseTask = nil
        analysisTask?.cancel()
        analysisTask = nil
        isUploading = false
        analysisPhase = .idle
    }
}
