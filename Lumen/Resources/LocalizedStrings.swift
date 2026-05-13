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
    static var welcomeSignInPrompt: String { localized("welcome.signin.prompt", fallback: "Already have an account?") }
    static var welcomeSignInLink: String { localized("welcome.signin.link", fallback: "tap here") }
    static var commonAnd: String { localized("common.and", fallback: "and") }
    static var commonOrContinueWith: String { localized("common.or.continue.with", fallback: "OR CONTINUE WITH") }
    static var authLoginFailed: String { localized("auth.login.failed", comment: "") }
    static var authCancelled: String { localized("auth.cancelled", comment: "") }
    static var authAppleTokenUnavailable: String { localized("auth.apple.token.unavailable", comment: "") }
    static var authGoogleNotConfigured: String { localized("auth.google.not.configured", comment: "") }
    static var authGoogleFailed: String { localized("auth.google.failed", comment: "") }
    
    static var levelSelectionTitle: String { localized("level.selection.title", comment: "") }
    static var levelSelectionDescription: String { localized("level.selection.description", comment: "") }
    static var levelBeginnerTitle: String { localized("level.beginner", fallback: "Beginner") }
    static var levelBeginnerDescription: String { localized("level.beginner.description", comment: "") }
    static var levelElementaryTitle: String { localized("level.elementary", fallback: "Elementary") }
    static var levelElementaryDescription: String { localized("level.elementary.description", comment: "") }
    static var levelIntermediateTitle: String { localized("level.intermediate", fallback: "Intermediate") }
    static var levelIntermediateDescription: String { localized("level.intermediate.description", comment: "") }
    static var levelUpperIntermediateTitle: String { localized("level.upperIntermediate", fallback: "Upper-Intermediate") }
    static var levelUpperIntermediateDescription: String { localized("level.upper.intermediate.description", comment: "") }
    static var levelAdvancedTitle: String { localized("level.advanced", fallback: "Advanced") }
    static var levelAdvancedDescription: String { localized("level.advanced.description", comment: "") }
    static var levelProficientTitle: String { localized("level.proficient", fallback: "Proficient") }
    static var levelProficientDescription: String { localized("level.proficient.description", fallback: "Understands subtle meaning and communicates with near-native ease.") }
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
    static var objectiveUnderstandPodcasts: String { localized("objective.understand.podcasts", fallback: "Understand podcasts") }
    static var objectiveExpandVocabulary: String { localized("objective.expand.vocabulary", comment: "") }
    static var objectivePassExams: String { localized("objective.pass.exams", comment: "") }
    static var objectiveImproveSpeaking: String { localized("objective.improve.speaking", comment: "") }
    static var objectiveDailyConversation: String { localized("objective.daily.conversation", comment: "") }
    static var objectiveProfessionalPresentations: String { localized("objective.professional.presentations", fallback: "Professional presentations") }
    static var objectiveJobInterviews: String { localized("objective.job.interviews", fallback: "Job interviews") }
    static var objectiveAirportConversations: String { localized("objective.airport.conversations", fallback: "Airport conversations") }
    static var objectiveHotelInteractions: String { localized("objective.hotel.interactions", fallback: "Hotel interactions") }
    static var objectiveMakingFriends: String { localized("objective.making.friends", fallback: "Making friends") }
    static var objectiveImprovePronunciation: String { localized("objective.improve.pronunciation", fallback: "Improve pronunciation") }
    static var objectiveImproveAccent: String { localized("objective.improve.accent", comment: "") }
    static var objectiveWritingEmails: String { localized("objective.writing.emails", fallback: "Write emails") }
    static var objectiveWritingMessages: String { localized("objective.writing.messages", fallback: "Write messages") }
    static var objectiveAcademicEnglish: String { localized("objective.academic.english", fallback: "Academic English") }
    static var objectiveStorytelling: String { localized("objective.storytelling", fallback: "Storytelling") }
    static var objectiveDebating: String { localized("objective.debating", fallback: "Debating") }
    static var objectiveReadingComprehension: String { localized("objective.reading.comprehension", comment: "") }
    static var objectiveWritingSkills: String { localized("objective.writing.skills", comment: "") }
    static var subtopicsTitle: String { localized("subtopics.title", fallback: "Optional subtopics") }
    static var subtopicsDescription: String { localized("subtopics.description", fallback: "Select more specific areas within your chosen topics. You can skip this step.") }
    static var subtopicsContinueButton: String { localized("subtopics.continue.button", fallback: "Continue") }
    static var subtopicsSkipButton: String { localized("subtopics.skip.button", fallback: "Skip for now") }
    static var contentStyleTitle: String { localized("content.style.title", fallback: "What content style do you prefer?") }
    static var contentStyleDescription: String { localized("content.style.description", fallback: "You can keep it mixed or highlight a favorite format.") }
    static var contentStyleContinueButton: String { localized("content.style.continue.button", fallback: "Continue") }
    static var professionTitle: String { localized("profession.title", fallback: "Your profession is optional") }
    static var professionDescription: String { localized("profession.description", fallback: "This helps personalize examples and contexts more relevant to you.") }
    static var professionSkipButton: String { localized("profession.skip.button", fallback: "Skip") }
    static var professionContinueButton: String { localized("profession.continue.button", fallback: "Finish") }
    
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
    static var feedContext: String { localized("feed.context", fallback: "Context") }
    static var feedExplanation: String { localized("feed.explanation", fallback: "Why this is useful") }
    static var feedDidYouKnow: String { localized("feed.did.you.know", fallback: "Did you know?") }
    static var feedShowDetails: String { localized("feed.show.details", fallback: "Show more") }
    static var feedHideDetails: String { localized("feed.hide.details", fallback: "Show less") }
    static var feedSpeak: String { localized("feed.speak", fallback: "Speak") }
    static var feedSpeakThisReel: String { localized("feed.speak.this.reel", fallback: "Speak This Reel") }
    static var feedTabFeed: String { localized("feed.tab.feed", fallback: "FEED") }
    static var feedTabSaved: String { localized("feed.tab.saved", fallback: "SAVED") }
    static var feedTabProfile: String { localized("feed.tab.profile", fallback: "PROFILE") }
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
    static var wordDetailsTitle: String { localized("word.details.title", fallback: "Word details") }
    static var wordDetailsExample: String { localized("word.details.example", fallback: "Example") }
    static var wordDetailsSaved: String { localized("word.details.saved", fallback: "Saved") }
    static var wordDetailsSaveWord: String { localized("word.details.save.word", fallback: "Save word") }
    static var wordDetailsHearPronunciation: String { localized("word.details.hear.pronunciation", fallback: "Hear pronunciation") }
    static var reelProgressLabel: String { localized("reel.progress.label", fallback: "Progress:") }
    static var reelCompleted: String { localized("reel.completed", fallback: "Reel completed") }
    static var interestsHint: String { localized("interests.hint", fallback: "Lumen AI will use these topics to generate contextual English phrases based on what you like.") }
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
    static var progressStudyDays: String { localized("progress.study.days", fallback: "Study Days") }
    static var progressAllTime: String { localized("progress.all.time", fallback: "all time") }
    static var progressThisWeek: String { localized("progress.this.week", fallback: "This Week") }
    static var progressMeaningfulReels: String { localized("progress.meaningful.reels", fallback: "meaningful reels") }
    static var progressReviews: String { localized("progress.reviews", fallback: "Reviews") }
    static var progressCompletedThisWeek: String { localized("progress.completed.this.week", fallback: "completed this week") }
    static var progressSpeaking: String { localized("progress.speaking", fallback: "Speaking") }
    static var progressXP: String { localized("progress.xp", fallback: "XP") }
    static var progressEarnedFromLearningActions: String { localized("progress.earned.from.learning.actions", fallback: "earned from learning actions") }
    static var progressStrongestTopics: String { localized("progress.strongest.topics", fallback: "Strongest Topics") }
    static var progressWeakestTopics: String { localized("progress.weakest.topics", fallback: "Weakest Topics") }
    static var progressCurrentStreak: String { localized("progress.current.streak", fallback: "Current streak") }
    static var progressStreakLabel: String { localized("progress.streak.label", fallback: "Streak") }
    static var progressLongestStreak: String { localized("progress.longest.streak", fallback: "Longest streak") }
    static var progressTodayStatus: String { localized("progress.today.status", fallback: "Today") }
    static var progressTodayGoal: String { localized("progress.today.goal", fallback: "Today's goal") }
    static var progressGoalCompleted: String { localized("progress.goal.completed", fallback: "Goal completed") }
    static var progressGoalInProgress: String { localized("progress.goal.in.progress", fallback: "In progress") }
    static var progressGoalKeepGoing: String { localized("progress.goal.keep.going", fallback: "Keep going today.") }
    static var progressGoalMomentum: String { localized("progress.goal.momentum", fallback: "You're on track today.") }
    static var progressStreakAlive: String { localized("progress.streak.alive", fallback: "Streak secured today.") }
    static var progressStreakKeepAlive: String { localized("progress.streak.keep.alive", fallback: "Keep your streak alive.") }
    static var progressDay: String { localized("progress.day", fallback: "day") }
    static var progressDays: String { localized("progress.days", fallback: "days") }
    static var progressComprehension: String { localized("progress.comprehension", fallback: "Comprehension") }
    static var progressWeeklyGoal: String { localized("progress.weekly.goal", fallback: "Weekly goal") }
    static var progressWeekRange: String { localized("progress.week.range", fallback: "Week") }
    static var progressNotEnoughTopicData: String { localized("progress.not.enough.topic.data", fallback: "Not enough topic data yet.") }
    static var progressCompShort: String { localized("progress.comp.short", fallback: "comp") }
    static var progressSpeakShort: String { localized("progress.speak.short", fallback: "speak") }
    static var speakingMicrophoneRequired: String { localized("speaking.error.microphone.required", fallback: "Microphone access is required to practice speaking.") }
    static var speakingRecordingStartFailed: String { localized("speaking.error.recording.start.failed", fallback: "Could not start recording.") }
    static var speakingRecordingFinishedFailed: String { localized("speaking.error.recording.finish.failed", fallback: "Recording did not finish correctly.") }
    static var speakingRecordBeforeSubmit: String { localized("speaking.error.record.before.submit", fallback: "Record your voice before submitting.") }
    static var speakingRecordingTooShort: String { localized("speaking.error.recording.too.short", fallback: "That recording was too short. Try again and say the full sentence.") }
    static var speakingRequestTimedOut: String { localized("speaking.error.timeout", fallback: "The request took too long. Try again with a shorter recording or check the connection.") }
    static var preferencesEnglishLevel: String { localized("preferences.english.level", comment: "") }
    static var preferencesNativeLanguage: String { localized("preferences.native.language", comment: "") }
    static var preferencesInterests: String { localized("preferences.interests", comment: "") }
    static var preferencesSubtopics: String { localized("preferences.subtopics", fallback: "Subtopics") }
    static var preferencesObjectives: String { localized("preferences.objectives", comment: "") }
    static var preferencesContentStyle: String { localized("preferences.content.style", fallback: "Content style") }
    static var preferencesProfession: String { localized("preferences.profession", fallback: "Profession") }
    static var preferencesSaveChanges: String { localized("preferences.save.changes", comment: "") }
    static var preferencesSaving: String { localized("preferences.saving", comment: "") }
    static var preferencesEditProfileTitle: String { localized("preferences.edit.profile.title", comment: "") }
    static var preferencesTitle: String { localized("preferences.title", fallback: "Settings") }
    static var preferencesPersonalInformation: String { localized("preferences.personal.information", fallback: "Personal Information") }
    static var preferencesFullName: String { localized("preferences.full.name", fallback: "FULL NAME") }
    static var preferencesEmailAddress: String { localized("preferences.email.address", fallback: "EMAIL ADDRESS") }
    static var preferencesNoEmailAvailable: String { localized("preferences.no.email.available", fallback: "No email available") }
    static var preferencesLearningContext: String { localized("preferences.learning.context", fallback: "Learning Context") }
    static var preferencesMemberSince: String { localized("preferences.member.since", fallback: "Lumen learner") }
    static var preferencesLevelHelperA1: String { localized("preferences.level.helper.a1", fallback: "Short, highly familiar sentences with daily vocabulary and strong contextual support.") }
    static var preferencesLevelHelperA2: String { localized("preferences.level.helper.a2", fallback: "Simple connected phrases for common situations, routines, and basic opinions.") }
    static var preferencesLevelHelperB1: String { localized("preferences.level.helper.b1", fallback: "Independent reading on familiar themes with more detail and clearer narratives.") }
    static var preferencesLevelHelperB2: String { localized("preferences.level.helper.b2", fallback: "More natural connected texts with richer ideas, contrast, and less frequent vocabulary.") }
    static var preferencesLevelHelperC1: String { localized("preferences.level.helper.c1", fallback: "Advanced texts with nuanced ideas, denser vocabulary, and more flexible grammar.") }
    static var preferencesLevelHelperC2: String { localized("preferences.level.helper.c2", fallback: "Near-native complexity with subtle tone, idioms, and culturally rich references.") }
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
    static var profileTitle: String { localized("profile.title", fallback: "Profile") }
    static var profileSettingsTitle: String { localized("profile.settings.title", fallback: "Settings") }
    static var profileReviewToday: String { localized("profile.review.today", fallback: "Review Today") }
    static var profileProgressOverview: String { localized("profile.progress.overview", fallback: "Progress Overview") }
    static var profileProfileSettings: String { localized("profile.profile.settings", fallback: "Profile Settings") }
    static var profileNotifications: String { localized("profile.notifications", fallback: "Notifications") }
    static var profileHelpFeedback: String { localized("profile.help.feedback", fallback: "Help & Feedback") }
    static var profileDefaultName: String { localized("profile.default.name", fallback: "Lumen Learner") }
    static var onboardingCompletionTitle: String { localized("onboarding.completion.title", fallback: "Creating your experience") }
    static var onboardingCompletionDescription: String { localized("onboarding.completion.description", fallback: "We are preparing your initial feed with the right level, your favorite topics, and personalized reels.") }
    static var onboardingCompletionStepAnalyze: String { localized("onboarding.completion.step.analyze", fallback: "Analyzing your interests") }
    static var onboardingCompletionStepBuild: String { localized("onboarding.completion.step.build", fallback: "Building your feed") }
    static var onboardingCompletionStepGenerate: String { localized("onboarding.completion.step.generate", fallback: "Generating the first reels") }
    static var reviewTodayItems: String { localized("review.today.items", fallback: "items") }
    static var reviewTodayItem: String { localized("review.today.item", fallback: "item") }
    static var reviewTodayGeneratedSummary: String { localized("review.today.generated.summary", fallback: "Generated or reused %@ review candidates for today.") }
    static var reviewTodaySpeakingReview: String { localized("review.today.speaking.review", fallback: "Speaking Review") }
    static var reviewTodayPracticeSpeaking: String { localized("review.today.practice.speaking", fallback: "Practice speaking") }
    static var speakingPracticeRepeatExactly: String { localized("speaking.practice.repeat.exactly", fallback: "Repeat exactly") }
    static var speakingPracticeInstruction: String { localized("speaking.practice.instruction", fallback: "Listen first if you want, then record your voice repeating the same sentence.") }
    static var speakingPracticeListenToTarget: String { localized("speaking.practice.listen.to.target", fallback: "Listen to target") }
    static var speakingPracticeRecording: String { localized("speaking.practice.recording", fallback: "Recording...") }
    static var speakingPracticeAnalyzing: String { localized("speaking.practice.analyzing", fallback: "Analyzing...") }
    static var speakingPracticeReady: String { localized("speaking.practice.ready", fallback: "Ready to practice") }
    static var speakingPracticeStopAndSubmit: String { localized("speaking.practice.stop.and.submit", fallback: "Stop and submit") }
    static var speakingPracticeStartRecording: String { localized("speaking.practice.start.recording", fallback: "Start recording") }
    static var speakingPracticeRetry: String { localized("speaking.practice.retry", fallback: "Retry") }
    static var speakingPracticeScore: String { localized("speaking.practice.score", fallback: "Pronunciation Score") }
    static var speakingPracticeSimilarity: String { localized("speaking.practice.similarity", fallback: "Similarity") }
    static var speakingPracticeYouSaid: String { localized("speaking.practice.you.said", fallback: "You said") }
    static var speakingPracticeMissingWords: String { localized("speaking.practice.missing.words", fallback: "Missing words") }
    static var speakingPracticePronunciationDifferences: String { localized("speaking.practice.pronunciation.differences", fallback: "Pronunciation differences") }
    static var speakingPracticeYouSaidLabel: String { localized("speaking.practice.you.said.label", fallback: "You said:") }
    static var speakingPracticeExpectedLabel: String { localized("speaking.practice.expected.label", fallback: "Expected:") }
    static var speakingPracticeFeedback: String { localized("speaking.practice.feedback", fallback: "Feedback") }
    
    static let feedLoadingTitle = localized("feed.loading.title", comment: "")
    static let feedLoadingDescription = localized("feed.loading.description", comment: "")
    static let feedErrorTitle = localized("feed.error.title", comment: "")
    static let feedErrorDescription = localized("feed.error.description", comment: "")
    static let feedErrorRetry = localized("feed.error.retry", comment: "")
    static let feedTailIdleTitle = localized("feed.tail.idle.title", comment: "")
    static let feedTailIdleDescription = localized("feed.tail.idle.description", comment: "")
    static let feedTailIdleAction = localized("feed.tail.idle.action", comment: "")

    // MARK: - ManualSignUpView toggle prompt
    static var signupNoAccountPrompt: String { localized("signup.no.account.prompt", fallback: "Don't have an account yet?") }

    // MARK: - Review types
    static var reviewTypeQuick: String { localized("review.type.quick", fallback: "Quick Review") }
    static var reviewTypeSpeaking: String { localized("review.type.speaking", fallback: "Speaking Review") }
    static var reviewTypeSaved: String { localized("review.type.saved", fallback: "Saved Review") }
    static var reviewTypeVocabulary: String { localized("review.type.vocabulary", fallback: "Vocabulary Review") }
    static var reviewTypeContextual: String { localized("review.type.contextual", fallback: "Contextual Review") }
    static func reviewOverdueDays(_ days: Int) -> String {
        String(format: localized("review.overdue.days", fallback: "%dd late"), days)
    }

    // MARK: - Phrase badges
    static var phraseBadgeFact: String { localized("phrase.badge.fact", fallback: "FACT") }
    static var phraseBadgeDialogue: String { localized("phrase.badge.dialogue", fallback: "DIALOGUE") }

    // MARK: - Error
    static var errorQuotaExceeded: String { localized("error.quota.exceeded", fallback: "Phrase generation is temporarily busy. Please try again in a few seconds.") }
}
