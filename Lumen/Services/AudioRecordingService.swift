import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioRecordingService: NSObject, ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var elapsedSeconds: TimeInterval = 0
    @Published private(set) var normalizedLevel: Float = 0
    @Published var errorMessage: String?

    private var recorder: AVAudioRecorder?
    private var timer: Timer?
    private var activeFileURL: URL?
    private var recordingStartedAt: Date?
    private var stopContinuation: CheckedContinuation<URL?, Never>?

    func startRecording() async -> Bool {
        errorMessage = nil

        guard await requestMicrophonePermission() else {
            errorMessage = LocalizedStrings.speakingMicrophoneRequired
            return false
        }

        stopTimer()
        deleteActiveFileIfNeeded()

        let fileURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("lumen-speaking-\(UUID().uuidString.lowercased())")
            .appendingPathExtension("m4a")

        // 16 kHz mono @ 32 kbps — optimal for speech; ~70 % smaller files vs 44.1 kHz / high.
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 32_000,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .spokenAudio, options: [.defaultToSpeaker, .allowBluetoothHFP])
            try session.setActive(true, options: .notifyOthersOnDeactivation)

            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.delegate = self
            guard recorder.record() else {
                errorMessage = LocalizedStrings.speakingRecordingStartFailed
                return false
            }

            self.recorder = recorder
            self.activeFileURL = fileURL
            self.recordingStartedAt = Date()
            self.elapsedSeconds = 0
            self.isRecording = true
            startTimer()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func stopRecording() async -> URL? {
        guard let recorder else { return activeFileURL }
        guard isRecording else { return activeFileURL }

        isRecording = false
        stopTimer()
        elapsedSeconds = max(elapsedSeconds, Date().timeIntervalSince(recordingStartedAt ?? Date()))

        return await withCheckedContinuation { continuation in
            stopContinuation = continuation
            recorder.stop()

            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .seconds(2))
                guard let self, self.stopContinuation != nil else { return }
                self.finishStoppingRecording(successfully: true, fallback: true)
            }
        }
    }

    func cancelRecording() {
        recorder?.stop()
        recorder = nil
        isRecording = false
        elapsedSeconds = 0
        stopTimer()
        if let stopContinuation {
            self.stopContinuation = nil
            stopContinuation.resume(returning: nil)
        }
        deactivateSessionIfPossible()
        deleteActiveFileIfNeeded()
        activeFileURL = nil
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.isRecording else { return }
                self.elapsedSeconds = Date().timeIntervalSince(self.recordingStartedAt ?? Date())
                // Expose normalised audio level (−60 dBFS → 0 dBFS mapped to 0–1)
                self.recorder?.updateMeters()
                let power = self.recorder?.averagePower(forChannel: 0) ?? -60
                self.normalizedLevel = Float(max(0, min(1, (power + 60) / 60)))
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func deleteActiveFileIfNeeded() {
        guard let activeFileURL else { return }
        try? FileManager.default.removeItem(at: activeFileURL)
    }

    private func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            } else {
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    private func deactivateSessionIfPossible() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Best effort only.
        }
    }

    private func finishStoppingRecording(successfully flag: Bool, fallback: Bool = false) {
        let urlToReturn = flag ? activeFileURL : nil
        recorder = nil
        deactivateSessionIfPossible()
        if let stopContinuation {
            self.stopContinuation = nil
            stopContinuation.resume(returning: urlToReturn)
        }
        if !flag {
            errorMessage = LocalizedStrings.speakingRecordingFinishedFailed
        } else if fallback {
            // Best effort only when the delegate doesn't respond promptly.
        }
    }
}

extension AudioRecordingService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in
            self.isRecording = false
            self.stopTimer()
            self.finishStoppingRecording(successfully: flag)
        }
    }
}
