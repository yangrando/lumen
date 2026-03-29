import Foundation

struct LocalizedStrings {
    private static func localized(_ key: String, fallback: String = "") -> String {
        NativeLanguageLocalization.localizedString(forKey: key, fallback: fallback)
    }

    static var appName: String { NSLocalizedString("app.name", comment: "") }
    // MARK: - Welcome Screen
    static var welcomeTitlePart1: String { NSLocalizedString("welcome.title.part1", comment: "") }
    static var welcomeTitlePart2: String { NSLocalizedString("welcome.title.part2", comment: "") }
    static var welcomeDescription: String { NSLocalizedString("welcome.description", comment: "") }
    static var welcomeButtonApple: String { NSLocalizedString("welcome.button.apple", comment: "") }
    static var welcomeButtonGoogle: String { NSLocalizedString("welcome.button.google", comment: "") }
    static var welcomeButtonEmail: String { NSLocalizedString("welcome.button.email", comment: "") }
    static var welcomeButtonAppleSignIn: String { NSLocalizedString("welcome.button.apple.signin", comment: "") }
    static var welcomeButtonAppleSignUp: String { NSLocalizedString("welcome.button.apple.signup", comment: "") }
    static var welcomeButtonGoogleSignIn: String { NSLocalizedString("welcome.button.google.signin", comment: "") }
    static var welcomeButtonGoogleSignUp: String { NSLocalizedString("welcome.button.google.signup", comment: "") }
    static var welcomeButtonEmailSignIn: String { NSLocalizedString("welcome.button.email.signin", comment: "") }
    static var welcomeButtonEmailSignUp: String { NSLocalizedString("welcome.button.email.signup", comment: "") }
    static var welcomeModeSignIn: String { NSLocalizedString("welcome.mode.signin", comment: "") }
    static var welcomeModeSignUp: String { NSLocalizedString("welcome.mode.signup", comment: "") }
    static var welcomeAuthHint: String { NSLocalizedString("welcome.auth.hint", comment: "") }
    static var welcomeTerms: String { NSLocalizedString("welcome.terms", comment: "") }
    static var welcomeTermsLink1: String { NSLocalizedString("welcome.terms.link1", comment: "") }
    static var welcomeTermsLink2: String { NSLocalizedString("welcome.terms.link2", comment: "") }
    static var authLoginFailed: String { NSLocalizedString("auth.login.failed", comment: "") }
    static var authCancelled: String { NSLocalizedString("auth.cancelled", comment: "") }
    static var authAppleTokenUnavailable: String { NSLocalizedString("auth.apple.token.unavailable", comment: "") }
    static var authGoogleNotConfigured: String { NSLocalizedString("auth.google.not.configured", comment: "") }
    static var authGoogleFailed: String { NSLocalizedString("auth.google.failed", comment: "") }
    
    static var levelSelectionTitle: String { NSLocalizedString("level.selection.title", comment: "") }
    static var levelSelectionDescription: String { NSLocalizedString("level.selection.description", comment: "") }
    static var levelBeginnerDescription: String { NSLocalizedString("level.beginner.description", comment: "") }
    static var levelElementaryDescription: String { NSLocalizedString("level.elementary.description", comment: "") }
    static var levelIntermediateDescription: String { NSLocalizedString("level.intermediate.description", comment: "") }
    static var levelUpperIntermediateDescription: String { NSLocalizedString("level.upper.intermediate.description", comment: "") }
    static var levelAdvancedDescription: String { NSLocalizedString("level.advanced.description", comment: "") }
    static var levelContinueButton: String { NSLocalizedString("level.continue.button", comment: "") }
    
    static var interestsTitle: String { NSLocalizedString("interests.title", comment: "") }
    static var interestsDescription: String { NSLocalizedString("interests.description", comment: "") }
    static var interestsContinueButton: String { NSLocalizedString("interests.continue.button", comment: "") }
    
    static var objectivesTitle: String { NSLocalizedString("objectives.title", comment: "") }
    static var objectivesDescription: String { NSLocalizedString("objectives.description", comment: "") }
    static var objectivesCompleteButton: String { NSLocalizedString("objectives.complete.button", comment: "") }
    static var objectivesPrimaryTitle: String { NSLocalizedString("objectives.primary.title", comment: "") }
    static var objectivesPrimaryDescription: String { NSLocalizedString("objectives.primary.description", comment: "") }
    static var objectiveBusinessCommunication: String { NSLocalizedString("objective.business.communication", comment: "") }
    static var objectiveTravelConfidence: String { NSLocalizedString("objective.travel.confidence", comment: "") }
    static var objectiveUnderstandMovies: String { NSLocalizedString("objective.understand.movies", comment: "") }
    static var objectiveExpandVocabulary: String { NSLocalizedString("objective.expand.vocabulary", comment: "") }
    static var objectivePassExams: String { NSLocalizedString("objective.pass.exams", comment: "") }
    static var objectiveImproveSpeaking: String { NSLocalizedString("objective.improve.speaking", comment: "") }
    static var objectiveDailyConversation: String { NSLocalizedString("objective.daily.conversation", comment: "") }
    static var objectiveImproveAccent: String { NSLocalizedString("objective.improve.accent", comment: "") }
    static var objectiveReadingComprehension: String { NSLocalizedString("objective.reading.comprehension", comment: "") }
    static var objectiveWritingSkills: String { NSLocalizedString("objective.writing.skills", comment: "") }
    
    static var completionTitle: String { NSLocalizedString("completion.title", comment: "") }
    static var completionDescription: String { NSLocalizedString("completion.description", comment: "") }
    static var completionStartButton: String { NSLocalizedString("completion.start.button", comment: "") }
    
    // MARK: - Main Feed Screen (Module 6)
    static var feedTitle: String { NSLocalizedString("feed.title", comment: "") }
    static var feedEmptyTitle: String { NSLocalizedString("feed.empty.title", comment: "") }
    static var feedEmptyDescription: String { NSLocalizedString("feed.empty.description", comment: "") }
    static var feedSaveButton: String { NSLocalizedString("feed.save.button", comment: "") }
    static var feedUnsaveButton: String { NSLocalizedString("feed.unsave.button", comment: "") }
    static var feedAIFeedback: String { NSLocalizedString("feed.ai.feedback", comment: "") }
    static var feedAskAI: String { NSLocalizedString("feed.ask.ai", comment: "") }
    static var feedListen: String { NSLocalizedString("feed.listen", comment: "") }
    static var feedStopAudio: String { NSLocalizedString("feed.stop.audio", comment: "") }
    static var feedTranslate: String { NSLocalizedString("feed.translate", comment: "") }
    static var feedReadingPlay: String { NSLocalizedString("feed.reading.play", comment: "") }
    static var feedReadingPause: String { NSLocalizedString("feed.reading.pause", comment: "") }
    static var feedReadingSpeed: String { NSLocalizedString("feed.reading.speed", comment: "") }
    static var feedDifficulty: String { NSLocalizedString("feed.difficulty", comment: "") }
    static var feedCategory: String { NSLocalizedString("feed.category", comment: "") }
    static var feedSavedPhrases: String { NSLocalizedString("feed.saved.phrases", comment: "") }
    static var feedAllPhrases: String { NSLocalizedString("feed.all.phrases", comment: "") }
    static var libraryEmptyTitle: String { NSLocalizedString("library.empty.title", comment: "") }
    static var libraryEmptyDescription: String { NSLocalizedString("library.empty.description", comment: "") }
    static var librarySearchPlaceholder: String { NSLocalizedString("library.search.placeholder", comment: "") }
    static var signupBack: String { NSLocalizedString("signup.back", comment: "") }
    static var signupTitle: String { NSLocalizedString("signup.title", comment: "") }
    static var signupSubtitle: String { NSLocalizedString("signup.subtitle", comment: "") }
    static var signinTitle: String { NSLocalizedString("signin.title", comment: "") }
    static var signinSubtitle: String { NSLocalizedString("signin.subtitle", comment: "") }
    static var signinLoading: String { NSLocalizedString("signin.loading", comment: "") }
    static var signupName: String { NSLocalizedString("signup.name", comment: "") }
    static var signupEmail: String { NSLocalizedString("signup.email", comment: "") }
    static var signupPassword: String { NSLocalizedString("signup.password", comment: "") }
    static var signupConfirmPassword: String { NSLocalizedString("signup.confirm.password", comment: "") }
    static var signupCreateButton: String { NSLocalizedString("signup.create.button", comment: "") }
    static var signupErrorRequiredFields: String { NSLocalizedString("signup.error.required.fields", comment: "") }
    static var signupErrorInvalidEmail: String { NSLocalizedString("signup.error.invalid.email", comment: "") }
    static var signupErrorPasswordLength: String { NSLocalizedString("signup.error.password.length", comment: "") }
    static var signupErrorPasswordMismatch: String { NSLocalizedString("signup.error.password.mismatch", comment: "") }
    static var signinButton: String { NSLocalizedString("signin.button", comment: "") }
    static var signupLoading: String { NSLocalizedString("signup.loading", comment: "") }
    static var accountLogout: String { NSLocalizedString("account.logout", comment: "") }
    static var accountDelete: String { NSLocalizedString("account.delete", comment: "") }
    static var accountCancel: String { NSLocalizedString("account.cancel", comment: "") }
    static var accountLogoutConfirmTitle: String { NSLocalizedString("account.logout.confirm.title", comment: "") }
    static var accountLogoutConfirmMessage: String { NSLocalizedString("account.logout.confirm.message", comment: "") }
    static var accountDeleteConfirmTitle: String { NSLocalizedString("account.delete.confirm.title", comment: "") }
    static var accountDeleteConfirmMessage: String { NSLocalizedString("account.delete.confirm.message", comment: "") }
    static var accountDeleteToastSuccessTitle: String { localized("account.delete.toast.success.title") }
    static var accountDeleteToastSuccessMessage: String { localized("account.delete.toast.success.message") }
    static var accountDeleteToastErrorTitle: String { localized("account.delete.toast.error.title") }
    static var accountDeleteToastErrorMessage: String { localized("account.delete.toast.error.message") }
    static var feedEditProfile: String { NSLocalizedString("feed.edit.profile", comment: "") }
    static var commonOk: String { localized("common.ok") }
    static var commonClose: String { localized("common.close") }
    static var commonRetry: String { localized("common.retry", fallback: "Try again") }
    static var commonErrorGeneric: String { localized("common.error.generic", fallback: "Something went wrong. Please try again.") }
    static var commonErrorTimeout: String { localized("common.error.timeout", fallback: "The request took too long. Please try again.") }
    static var commonErrorConnection: String { localized("common.error.connection", fallback: "Please check your connection and try again.") }
    static var commonErrorUnauthenticated: String { localized("common.error.unauthenticated", fallback: "Please sign in again to continue.") }
    static var feedbackSuccessTitle: String { localized("feedback.success.title", fallback: "Success") }
    static var feedbackErrorTitle: String { localized("feedback.error.title", fallback: "Error") }
    static var savedReelsSyncError: String { localized("saved.reels.sync.error", fallback: "We couldn't sync your saved reels right now.") }
    static var savedReelsRemoved: String { localized("saved.reels.removed", fallback: "Reel removed from saved items.") }
    static var savedReelsSaved: String { localized("saved.reels.saved", fallback: "Reel saved successfully.") }
    static var reviewTodayTitle: String { localized("review.today.title", fallback: "Review Today") }
    static var reviewTodayLoadingTitle: String { localized("review.today.loading.title", fallback: "Preparing your review queue") }
    static var reviewTodayLoadingDescription: String { localized("review.today.loading.description", fallback: "We are selecting the most relevant items for today.") }
    static var reviewTodayErrorTitle: String { localized("review.today.error.title", fallback: "Could not load Review Today") }
    static var reviewTodayEmptyTitle: String { localized("review.today.empty.title", fallback: "Nothing due today") }
    static var reviewTodayEmptyDescription: String { localized("review.today.empty.description", fallback: "Keep exploring the feed and saving useful reels. New review items will appear as your learning signals build up.") }
    static var progressTitle: String { localized("progress.title", fallback: "Progress") }
    static var progressLoadingTitle: String { localized("progress.loading.title", fallback: "Loading your progress") }
    static var progressLoadingDescription: String { localized("progress.loading.description", fallback: "We are summarizing your recent study activity.") }
    static var progressErrorTitle: String { localized("progress.error.title", fallback: "Could not load progress") }
    static var progressEmptyTitle: String { localized("progress.empty.title", fallback: "Your progress will appear here") }
    static var progressEmptyDescription: String { localized("progress.empty.description", fallback: "Complete a few meaningful reels, a review session, or a speaking session to start building your stats.") }
    static var speakingMicrophoneRequired: String { localized("speaking.error.microphone.required", fallback: "Microphone access is required to practice speaking.") }
    static var speakingRecordingStartFailed: String { localized("speaking.error.recording.start.failed", fallback: "Could not start recording.") }
    static var speakingRecordingFinishedFailed: String { localized("speaking.error.recording.finish.failed", fallback: "Recording did not finish correctly.") }
    static var speakingRecordBeforeSubmit: String { localized("speaking.error.record.before.submit", fallback: "Record your voice before submitting.") }
    static var speakingRecordingTooShort: String { localized("speaking.error.recording.too.short", fallback: "That recording was too short. Try again and say the full sentence.") }
    static var speakingRequestTimedOut: String { localized("speaking.error.timeout", fallback: "The request took too long. Try again with a shorter recording or check the connection.") }
    static var preferencesEnglishLevel: String { NSLocalizedString("preferences.english.level", comment: "") }
    static var preferencesNativeLanguage: String { NSLocalizedString("preferences.native.language", comment: "") }
    static var preferencesInterests: String { NSLocalizedString("preferences.interests", comment: "") }
    static var preferencesObjectives: String { NSLocalizedString("preferences.objectives", comment: "") }
    static var preferencesSaveChanges: String { NSLocalizedString("preferences.save.changes", comment: "") }
    static var preferencesSaving: String { NSLocalizedString("preferences.saving", comment: "") }
    static var preferencesEditProfileTitle: String { NSLocalizedString("preferences.edit.profile.title", comment: "") }
    static var nativeLanguageTitle: String { NSLocalizedString("native.language.title", comment: "") }
    static var nativeLanguageDescription: String { NSLocalizedString("native.language.description", comment: "") }
    static var nativeLanguageOptionPortugueseBrazil: String { NSLocalizedString("native.language.option.portuguese.brazil", comment: "") }
    static var nativeLanguageOptionSpanish: String { NSLocalizedString("native.language.option.spanish", comment: "") }
    static var nativeLanguageOptionEnglish: String { NSLocalizedString("native.language.option.english", comment: "") }
    static var nativeLanguageOptionFrench: String { NSLocalizedString("native.language.option.french", comment: "") }
    static var nativeLanguageOptionGerman: String { NSLocalizedString("native.language.option.german", comment: "") }
    static var nativeLanguageOptionItalian: String { NSLocalizedString("native.language.option.italian", comment: "") }
    static var nativeLanguageOptionRussian: String { NSLocalizedString("native.language.option.russian", comment: "") }
    static var nativeLanguageOptionJapanese: String { NSLocalizedString("native.language.option.japanese", comment: "") }
    static var nativeLanguageOptionKorean: String { NSLocalizedString("native.language.option.korean", comment: "") }
    static var nativeLanguageOptionChineseSimplified: String { NSLocalizedString("native.language.option.chinese.simplified", comment: "") }
    static var feedbackUnavailable: String { NSLocalizedString("feedback.unavailable", comment: "") }
    static var translationUnavailable: String { NSLocalizedString("translation.unavailable", comment: "") }
    static var askAITitle: String { NSLocalizedString("ask.ai.title", comment: "") }
    static var askAISubtitle: String { NSLocalizedString("ask.ai.subtitle", comment: "") }
    static var askAIPlaceholder: String { NSLocalizedString("ask.ai.placeholder", comment: "") }
    static var askAISend: String { NSLocalizedString("ask.ai.send", comment: "") }
    static var askAIThinking: String { NSLocalizedString("ask.ai.thinking", comment: "") }
    static var askAIRecord: String { NSLocalizedString("ask.ai.record", comment: "") }
    static var askAIStopRecord: String { NSLocalizedString("ask.ai.stop.record", comment: "") }
    static var askAIAudioPermissionDenied: String { NSLocalizedString("ask.ai.audio.permission.denied", comment: "") }
    static var askAISpeechUnavailable: String { NSLocalizedString("ask.ai.speech.unavailable", comment: "") }
    static var askAIQuestionRequired: String { NSLocalizedString("ask.ai.question.required", comment: "") }
    
    static let feedLoadingTitle = NSLocalizedString("feed.loading.title", comment: "")
    static let feedLoadingDescription = NSLocalizedString("feed.loading.description", comment: "")
    static let feedErrorTitle = NSLocalizedString("feed.error.title", comment: "")
    static let feedErrorDescription = NSLocalizedString("feed.error.description", comment: "")
    static let feedErrorRetry = NSLocalizedString("feed.error.retry", comment: "")
    static let feedTailIdleTitle = NSLocalizedString("feed.tail.idle.title", comment: "")
    static let feedTailIdleDescription = NSLocalizedString("feed.tail.idle.description", comment: "")
    static let feedTailIdleAction = NSLocalizedString("feed.tail.idle.action", comment: "")
}
