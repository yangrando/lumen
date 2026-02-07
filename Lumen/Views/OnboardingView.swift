import SwiftUI

struct OnboardingView: View {
    enum OnboardingStep {
        case welcome
        case levelSelection
        case interests
        case objectives
        case completion
    }
    
    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedLevel: EnglishLevel? = nil
    @State private var selectedInterests: [UserInterest] = []
    @State private var selectedObjectives: [LearningObjective] = []

    
    var body: some View {
        NavigationStack {
            switch currentStep {
            case .welcome:
                WelcomeView(onContinue: {
                    currentStep = .levelSelection
                })
            case .levelSelection:
                LevelSelectionView(onContinue: { level in
                    selectedLevel = level
                    currentStep = .interests
                })
            case .interests:
                InterestsView(onContinue: { interests in
                    selectedInterests = interests
                    currentStep = .objectives
                })
            case .objectives:
                ObjectivesView(onContinue: { objectives in
                    selectedObjectives = objectives
                    currentStep = .completion
                })
            case .completion:
                OnboardingCompletionView()
            }
        }
    }
}

#Preview {
    OnboardingView()
}
