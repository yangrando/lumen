import Foundation
import Speech
import AVFoundation
import Combine

@MainActor
final class SpeechToTextService: NSObject, ObservableObject {
    enum ToggleResult {
        case started
        case stopped
        case failed
    }

    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer? {
        // Keep English recognition by default because user questions are about English phrases.
        SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }

    func toggleRecording() async -> ToggleResult {
        if isRecording {
            stopRecording()
            return .stopped
        } else {
            return await startRecording()
        }
    }

    func stopRecording() {
        audioEngine.stop()
        if audioEngine.inputNode.numberOfInputs > 0 || audioEngine.inputNode.numberOfOutputs > 0 {
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        audioEngine.reset()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
        deactivateSessionIfPossible()
    }

    private func startRecording() async -> ToggleResult {
        errorMessage = nil

        guard await requestPermissions() else {
            errorMessage = LocalizedStrings.askAIAudioPermissionDenied
            return .failed
        }

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            errorMessage = LocalizedStrings.askAISpeechUnavailable
            return .failed
        }

        stopRecording()
        transcript = ""

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.defaultToSpeaker, .allowBluetoothHFP, .mixWithOthers]
            )
            try session.setPreferredSampleRate(44_100)
            try session.setPreferredInputNumberOfChannels(1)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = error.localizedDescription
            return .failed
        }

        audioEngine.reset()

        guard let format = await acquireValidInputFormat() else {
            errorMessage = LocalizedStrings.askAIAudioInputUnavailable
            recognitionRequest = nil
            deactivateSessionIfPossible()
            return .failed
        }

        let inputNode = audioEngine.inputNode
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            errorMessage = error.localizedDescription
            return .failed
        }

        isRecording = true

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }
            if let result {
                Task { @MainActor in
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if error != nil {
                Task { @MainActor in
                    self.stopRecording()
                }
            }
        }
        return .started
    }

    private func requestPermissions() async -> Bool {
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }

        let micAllowed = await withCheckedContinuation { continuation in
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

        return speechAllowed && micAllowed
    }

    private func deactivateSessionIfPossible() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // Best effort only.
        }
    }

    private func acquireValidInputFormat() async -> AVAudioFormat? {
        for _ in 0..<6 {
            let inputNode = audioEngine.inputNode
            let preferred = inputNode.inputFormat(forBus: 0)
            if preferred.sampleRate > 0, preferred.channelCount > 0 {
                return preferred
            }

            let fallback = inputNode.outputFormat(forBus: 0)
            if fallback.sampleRate > 0, fallback.channelCount > 0 {
                return fallback
            }

            try? await Task.sleep(for: .milliseconds(250))
        }
        return nil
    }
}
