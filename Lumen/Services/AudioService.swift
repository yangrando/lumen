import Foundation
import AVFoundation
import Combine

@MainActor
final class AudioService: NSObject, ObservableObject {
    static let shared = AudioService()

    @Published private(set) var currentlyPlayingPhraseID: UUID?

    private let synthesizer = AVSpeechSynthesizer()
    private let speechVolume: Float = 0.75

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    func togglePlayback(for phraseID: UUID, text: String) {
        if currentlyPlayingPhraseID == phraseID && synthesizer.isSpeaking {
            stop()
            return
        }

        play(text: text, phraseID: phraseID)
    }

    func stop() {
        guard synthesizer.isSpeaking else {
            currentlyPlayingPhraseID = nil
            return
        }

        synthesizer.stopSpeaking(at: .immediate)
        currentlyPlayingPhraseID = nil
    }

    private func play(text: String, phraseID: UUID) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        configureAudioSession()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = preferredVoice()
        utterance.rate = 0.47
        utterance.pitchMultiplier = 1.0
        // Keep speech under max gain so device media volume remains user-controllable.
        utterance.volume = speechVolume

        currentlyPlayingPhraseID = phraseID
        synthesizer.speak(utterance)
    }

    private func preferredVoice() -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        let preferredLanguages = ["en-US", "en-GB"]

        let preferredVoices = voices.filter { preferredLanguages.contains($0.language) }

        if let highQualityPreferred = preferredVoices.first(where: { $0.quality == .premium }) {
            return highQualityPreferred
        }

        if let enhancedPreferred = preferredVoices.first(where: { $0.quality == .enhanced }) {
            return enhancedPreferred
        }

        if let defaultPreferred = preferredVoices.first {
            return defaultPreferred
        }

        let anyEnglishVoices = voices.filter { $0.language.hasPrefix("en") }

        if let highQualityEnglish = anyEnglishVoices.first(where: { $0.quality == .premium }) {
            return highQualityEnglish
        }

        if let enhancedEnglish = anyEnglishVoices.first(where: { $0.quality == .enhanced }) {
            return enhancedEnglish
        }

        return anyEnglishVoices.first ?? AVSpeechSynthesisVoice(language: "en-US")
    }

    private func configureAudioSession() {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(
                .playAndRecord,
                mode: .default,
                options: [.defaultToSpeaker, .allowBluetooth, .mixWithOthers]
            )
            try session.setActive(true)
        } catch {
            print("Audio session configuration failed: \(error.localizedDescription)")
        }
    }
}

extension AudioService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.currentlyPlayingPhraseID = nil
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.currentlyPlayingPhraseID = nil
        }
    }
}
