import Foundation

enum ContentStylePreference: String, CaseIterable, Identifiable {
    case mixed = "Mixed"
    case conversation = "Conversation"
    case dialogue = "Dialogue"
    case expression = "Expression"
    case miniFact = "Mini Fact"
    case cultureTip = "Culture Tip"
    case practicalPhrase = "Practical Phrase"
    case scenario = "Scenario"
    case didYouKnow = "Did You Know"

    var id: String { rawValue }

    var displayTitle: String {
        switch self {
        case .mixed:
            return "Misto"
        case .conversation:
            return "Conversas"
        case .dialogue:
            return "Diálogos"
        case .expression:
            return "Expressões"
        case .miniFact:
            return "Mini fatos"
        case .cultureTip:
            return "Dicas culturais"
        case .practicalPhrase:
            return "Frases práticas"
        case .scenario:
            return "Cenários"
        case .didYouKnow:
            return "Você sabia?"
        }
    }
}
