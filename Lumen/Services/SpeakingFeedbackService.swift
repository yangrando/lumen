import Foundation
import SwiftUI

struct SpeakingFeedbackSummary {
    let title: String
    let subtitle: String
    let scoreColor: Color
}

enum SpeakingFeedbackService {
    static func summary(for attempt: SpeakingAttempt) -> SpeakingFeedbackSummary {
        if attempt.score >= 80 {
            return SpeakingFeedbackSummary(
                title: NativeLanguageLocalization.localizedString(forKey: "speaking.feedback.good", fallback: "Good pronunciation"),
                subtitle: NativeLanguageLocalization.localizedString(forKey: "speaking.feedback.good.subtitle", fallback: "Your pronunciation is clear and close to the expected sentence."),
                scoreColor: Color(red: 0.27, green: 0.81, blue: 0.60)
            )
        }
        return SpeakingFeedbackSummary(
            title: NativeLanguageLocalization.localizedString(forKey: "speaking.feedback.improve", fallback: "Needs improvement"),
            subtitle: NativeLanguageLocalization.localizedString(forKey: "speaking.feedback.improve.subtitle", fallback: "Try again and focus on the highlighted words."),
            scoreColor: Color(red: 1.0, green: 0.63, blue: 0.25)
        )
    }
}
