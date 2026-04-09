import Foundation

struct LocalizedStrings {
    private static func localized(_ key: String, fallback: String = "", comment: String = "") -> String {
        NativeLanguageLocalization.localizedString(forKey: key, fallback: fallback)
    }

    static var appName: String { localized("app.name", comment: "") }
    // MARK: - Welcome Screen
    static var welcomeTitlePart1: String { localized("welcome.title.part1", comment: "") }
    static var welcomeTitlePart2: String { localized("welcome.title.part2", comment: "") }
    static var welcomeDescription: String { localized("welcome.description", comment: "") }
    static var welcomeButtonApple: String { localized("welcome.button.apple", comment: "") }
    static var welcomeButtonGoogle: String { localized("welcome.button.google", comment: "") }
    static var welcomeButtonEmail: String { localized("welcome.button.email", comment: "") }
    static var welcomeButtonAppleSignIn: String { localized("welcome.button.apple.signin", comment: "") }
    static var welcomeButtonAppleSignUp: String { localized("welcome.button.apple.signup", comment: "") }
    static var welcomeButtonGoogleSignIn: String { localized("welcome.button.google.signin", comment: "") }
    static var welcomeButtonGoogleSignUp: String { localized("welcome.button.google.signup", comment: "") }
    static var welcomeButtonEmailSignIn: String { localized("welcome.button.email.signin", comment: "") }
    static var welcomeButtonEmailSignUp: String { localized("welcome.button.email.signup", comment: "") }
    static var welcomeModeSignIn: String { localized("welcome.mode.signin", comment: "") }
    static var welcomeModeSignUp: String { localized("welcome.mode.signup", comment: "") }
    static var welcomeAuthHint: String { localized("welcome.auth.hint", comment: "") }
    static var welcomeTerms: String { localized("welcome.terms", comment: "") }
    static var welcomeTermsLink1: String { localized("welcome.terms.link1", comment: "") }
    static var welcomeTermsLink2: String { localized("welcome.terms.link2", comment: "") }
    static var authLoginFailed: String { localized("auth.login.failed", comment: "") }
    static var authCancelled: String { localized("auth.cancelled", comment: "") }
    static var authAppleTokenUnavailable: String { localized("auth.apple.token.unavailable", comment: "") }
    static var authGoogleNotConfigured: String { localized("auth.google.not.configured", comment: "") }
    static var authGoogleFailed: String { localized("auth.google.failed", comment: "") }
    
    static var levelSelectionTitle: String { localized("level.selection.title", comment: "") }
    static var levelSelectionDescription: String { localized("level.selection.description", comment: "") }
    static var levelBeginnerDescription: String { localized("level.beginner.description", comment: "") }
    static var levelElementaryDescription: String { localized("level.elementary.description", comment: "") }
    static var levelIntermediateDescription: String { localized("level.intermediate.description", comment: "") }
    static var levelUpperIntermediateDescription: String { localized("level.upper.intermediate.description", comment: "") }
    static var levelAdvancedDescription: String { localized("level.advanced.description", comment: "") }
    static var levelContinueButton: String { localized("level.continue.button", comment: "") }
    
    static var interestsTitle: String { localized("interests.title", comment: "") }
    static var interestsDescription: String { localized("interests.description", comment: "") }
    static var interestsContinueButton: String { localized("interests.continue.button", comment: "") }
    
    static var objectivesTitle: String { localized("objectives.title", comment: "") }
    static var objectivesDescription: String { localized("objectives.description", comment: "") }
    static var objectivesCompleteButton: String { localized("objectives.complete.button", comment: "") }
    static var objectivesPrimaryTitle: String { localized("objectives.primary.title", comment: "") }
    static var objectivesPrimaryDescription: String { localized("objectives.primary.description", comment: "") }
    static var objectiveBusinessCommunication: String { localized("objective.business.communication", comment: "") }
    static var objectiveTravelConfidence: String { localized("objective.travel.confidence", comment: "") }
    static var objectiveUnderstandMovies: String { localized("objective.understand.movies", comment: "") }
    static var objectiveExpandVocabulary: String { localized("objective.expand.vocabulary", comment: "") }
    static var objectivePassExams: String { localized("objective.pass.exams", comment: "") }
    static var objectiveImproveSpeaking: String { localized("objective.improve.speaking", comment: "") }
    static var objectiveDailyConversation: String { localized("objective.daily.conversation", comment: "") }
    static var objectiveImproveAccent: String { localized("objective.improve.accent", comment: "") }
    static var objectiveReadingComprehension: String { localized("objective.reading.comprehension", comment: "") }
    static var objectiveWritingSkills: String { localized("objective.writing.skills", comment: "") }
    
    static var completionTitle: String { localized("completion.title", comment: "") }
    static var completionDescription: String { localized("completion.description", comment: "") }
    static var completionStartButton: String { localized("completion.start.button", comment: "") }
    
    // MARK: - Main Feed Screen (Module 6)
    static var feedTitle: String { localized("feed.title", comment: "") }
    static var feedEmptyTitle: String { localized("feed.empty.title", comment: "") }
    static var feedEmptyDescription: String { localized("feed.empty.description", comment: "") }
    static var feedSaveButton: String { localized("feed.save.button", comment: "") }
    static var feedUnsaveButton: String { localized("feed.unsave.button", comment: "") }
    static var feedAIFeedback: String { localized("feed.ai.feedback", comment: "") }
    static var feedAskAI: String { localized("feed.ask.ai", comment: "") }
    static var feedListen: String { localized("feed.listen", comment: "") }
    static var feedStopAudio: String { localized("feed.stop.audio", comment: "") }
    static var feedTranslate: String { localized("feed.translate", comment: "") }
    static var feedReadingPlay: String { localized("feed.reading.play", comment: "") }
    static var feedReadingPause: String { localized("feed.reading.pause", comment: "") }
    static var feedReadingSpeed: String { localized("feed.reading.speed", comment: "") }
    static var feedDifficulty: String { localized("feed.difficulty", comment: "") }
    static var feedCategory: String { localized("feed.category", comment: "") }
    static var feedSavedPhrases: String { localized("feed.saved.phrases", comment: "") }
    static var feedAllPhrases: String { localized("feed.all.phrases", comment: "") }
    static var libraryEmptyTitle: String { localized("library.empty.title", comment: "") }
    static var libraryEmptyDescription: String { localized("library.empty.description", comment: "") }
    static var librarySearchPlaceholder: String { localized("library.search.placeholder", comment: "") }
    static var signupBack: String { localized("signup.back", comment: "") }
    static var signupTitle: String { localized("signup.title", comment: "") }
    static var signupSubtitle: String { localized("signup.subtitle", comment: "") }
    static var signinTitle: String { localized("signin.title", comment: "") }
    static var signinSubtitle: String { localized("signin.subtitle", comment: "") }
    static var signinLoading: String { localized("signin.loading", comment: "") }
    static var signupName: String { localized("signup.name", comment: "") }
    static var signupEmail: String { localized("signup.email", comment: "") }
    static var signupPassword: String { localized("signup.password", comment: "") }
    static var signupConfirmPassword: String { localized("signup.confirm.password", comment: "") }
    static var signupCreateButton: String { localized("signup.create.button", comment: "") }
    static var signupErrorRequiredFields: String { localized("signup.error.required.fields", comment: "") }
    static var signupErrorInvalidEmail: String { localized("signup.error.invalid.email", comment: "") }
    static var signupErrorPasswordLength: String { localized("signup.error.password.length", comment: "") }
    static var signupErrorPasswordMismatch: String { localized("signup.error.password.mismatch", comment: "") }
    static var signinButton: String { localized("signin.button", comment: "") }
    static var signupLoading: String { localized("signup.loading", comment: "") }
    static var accountLogout: String { localized("account.logout", comment: "") }
    static var accountDelete: String { localized("account.delete", comment: "") }
    static var accountCancel: String { localized("account.cancel", comment: "") }
    static var accountLogoutConfirmTitle: String { localized("account.logout.confirm.title", comment: "") }
    static var accountLogoutConfirmMessage: String { localized("account.logout.confirm.message", comment: "") }
    static var accountDeleteConfirmTitle: String { localized("account.delete.confirm.title", comment: "") }
    static var accountDeleteConfirmMessage: String { localized("account.delete.confirm.message", comment: "") }
    static var accountDeleteToastSuccessTitle: String { localized("account.delete.toast.success.title") }
    static var accountDeleteToastSuccessMessage: String { localized("account.delete.toast.success.message") }
    static var accountDeleteToastErrorTitle: String { localized("account.delete.toast.error.title") }
    static var accountDeleteToastErrorMessage: String { localized("account.delete.toast.error.message") }
    static var feedEditProfile: String { localized("feed.edit.profile", comment: "") }
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
    static var preferencesEnglishLevel: String { localized("preferences.english.level", comment: "") }
    static var preferencesNativeLanguage: String { localized("preferences.native.language", comment: "") }
    static var preferencesInterests: String { localized("preferences.interests", comment: "") }
    static var preferencesObjectives: String { localized("preferences.objectives", comment: "") }
    static var preferencesSaveChanges: String { localized("preferences.save.changes", comment: "") }
    static var preferencesSaving: String { localized("preferences.saving", comment: "") }
    static var preferencesEditProfileTitle: String { localized("preferences.edit.profile.title", comment: "") }
    static var nativeLanguageTitle: String { localized("native.language.title", comment: "") }
    static var nativeLanguageDescription: String { localized("native.language.description", comment: "") }
    static var nativeLanguageOptionPortugueseBrazil: String { localized("native.language.option.portuguese.brazil", comment: "") }
    static var nativeLanguageOptionSpanish: String { localized("native.language.option.spanish", comment: "") }
    static var nativeLanguageOptionEnglish: String { localized("native.language.option.english", comment: "") }
    static var nativeLanguageOptionFrench: String { localized("native.language.option.french", comment: "") }
    static var nativeLanguageOptionGerman: String { localized("native.language.option.german", comment: "") }
    static var nativeLanguageOptionItalian: String { localized("native.language.option.italian", comment: "") }
    static var nativeLanguageOptionRussian: String { localized("native.language.option.russian", comment: "") }
    static var nativeLanguageOptionJapanese: String { localized("native.language.option.japanese", comment: "") }
    static var nativeLanguageOptionKorean: String { localized("native.language.option.korean", comment: "") }
    static var nativeLanguageOptionChineseSimplified: String { localized("native.language.option.chinese.simplified", comment: "") }
    static var feedbackUnavailable: String { localized("feedback.unavailable", comment: "") }
    static var translationUnavailable: String { localized("translation.unavailable", comment: "") }
    static var askAITitle: String { localized("ask.ai.title", comment: "") }
    static var askAISubtitle: String { localized("ask.ai.subtitle", comment: "") }
    static var askAIPlaceholder: String { localized("ask.ai.placeholder", comment: "") }
    static var askAISend: String { localized("ask.ai.send", comment: "") }
    static var askAIThinking: String { localized("ask.ai.thinking", comment: "") }
    static var askAIRecord: String { localized("ask.ai.record", comment: "") }
    static var askAIStopRecord: String { localized("ask.ai.stop.record", comment: "") }
    static var askAIAudioPermissionDenied: String { localized("ask.ai.audio.permission.denied", comment: "") }
    static var askAISpeechUnavailable: String { localized("ask.ai.speech.unavailable", comment: "") }
    static var askAIAudioInputUnavailable: String { localized("ask.ai.audio.input.unavailable", fallback: "Microphone input is not available right now. Try again in a moment.") }
    static var askAIQuestionRequired: String { localized("ask.ai.question.required", comment: "") }
    
    static let feedLoadingTitle = localized("feed.loading.title", comment: "")
    static let feedLoadingDescription = localized("feed.loading.description", comment: "")
    static let feedErrorTitle = localized("feed.error.title", comment: "")
    static let feedErrorDescription = localized("feed.error.description", comment: "")
    static let feedErrorRetry = localized("feed.error.retry", comment: "")
    static let feedTailIdleTitle = localized("feed.tail.idle.title", comment: "")
    static let feedTailIdleDescription = localized("feed.tail.idle.description", comment: "")
    static let feedTailIdleAction = localized("feed.tail.idle.action", comment: "")
}
