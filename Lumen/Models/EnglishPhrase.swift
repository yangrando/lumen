//
//  EnglishPhrase.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 04/01/26.
//

import Foundation


struct EnglishPhrase: Identifiable, Equatable {
    
    let id: UUID
    let reelID: String
    let text: String
    let translation: String
    let difficulty: DifficultyLevel
    let category: String
    let example: String?
    let audioURL: URL?
    let goal: String?
    let subtopic: String?
    let contentType: String?
    let contentTemplate: String?
    let contentStyle: String?
    let context: String?
    let explanation: String?
    let didYouKnow: String?
    let keywords: [String]
    let focusWords: [String]
    let grammarFocus: String?
    let speakingSuitable: Bool
    let reviewPriorityHint: String?
    let generationExplanation: String?
    let difficultyMode: String?
    
    init(
        id: UUID = UUID(),
        reelID: String = "",
        text: String,
        translation: String,
        difficulty: DifficultyLevel,
        category: String,
        example: String? = nil,
        audioURL: URL? = nil,
        goal: String? = nil,
        subtopic: String? = nil,
        contentType: String? = nil,
        contentTemplate: String? = nil,
        contentStyle: String? = nil,
        context: String? = nil,
        explanation: String? = nil,
        didYouKnow: String? = nil,
        keywords: [String] = [],
        focusWords: [String] = [],
        grammarFocus: String? = nil,
        speakingSuitable: Bool = false,
        reviewPriorityHint: String? = nil,
        generationExplanation: String? = nil,
        difficultyMode: String? = nil
    ) {
        self.id = id
        self.reelID = reelID
        self.text = text
        self.translation = translation
        self.difficulty = difficulty
        self.category = category
        self.example = example
        self.audioURL = audioURL
        self.goal = goal
        self.subtopic = subtopic
        self.contentType = contentType
        self.contentTemplate = contentTemplate
        self.contentStyle = contentStyle
        self.context = context
        self.explanation = explanation
        self.didYouKnow = didYouKnow
        self.keywords = keywords
        self.focusWords = focusWords
        self.grammarFocus = grammarFocus
        self.speakingSuitable = speakingSuitable
        self.reviewPriorityHint = reviewPriorityHint
        self.generationExplanation = generationExplanation
        self.difficultyMode = difficultyMode
    }
    
    static func == (lhs: EnglishPhrase, rhs: EnglishPhrase) -> Bool {
        lhs.id == rhs.id
    }

    var hasStructuredDetails: Bool {
        [context, explanation, didYouKnow].contains { value in
            guard let value else { return false }
            return !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    var isDialogueLike: Bool {
        text.contains("\n") || (contentTemplate ?? "").lowercased().contains("dialog") || (contentType ?? "").lowercased() == "dialogue"
    }

    var isFactLike: Bool {
        let template = (contentTemplate ?? "").lowercased()
        return template.contains("fact") || template.contains("culture tip") || template.contains("did you know")
    }

}

enum DifficultyLevel: String, CaseIterable {
    case a1 = "A1"
    case a2 = "A2"
    case b1 = "B1"
    case b2 = "B2"
    case c1 = "C1"
    case c2 = "C2"

    init(label: String) {
        let normalized = label
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: " ", with: "")

        switch normalized {
        case "a1", "beginner":
            self = .a1
        case "a2", "elementary", "preintermediate":
            self = .a2
        case "b1", "intermediate":
            self = .b1
        case "b2", "upperintermediate":
            self = .b2
        case "c1", "advanced":
            self = .c1
        case "c2", "proficient", "mastery":
            self = .c2
        default:
            self = .b1
        }
    }
}

extension EnglishPhrase {
    static let mockPhrases: [EnglishPhrase] = [
        EnglishPhrase(
            text: "How are you doing today?",
            translation: "Como você está hoje?",
            difficulty: .a1,
            category: "Greetings",
            example: "A: How are you doing today? B: I'm doing great, thanks for asking!"
        ),
        EnglishPhrase(
            text: "I've been looking forward to this moment.",
            translation: "Eu estava ansioso por este momento.",
            difficulty: .b1,
            category: "Emotions",
            example: "I've been looking forward to this moment for weeks."
        ),
        EnglishPhrase(
            text: "Could you lend me a hand?",
            translation: "Você poderia me dar uma mão?",
            difficulty: .a2,
            category: "Requests",
            example: "Could you lend me a hand with this project?"
        ),
        EnglishPhrase(
            text: "The ball is in your court now.",
            translation: "Agora é a sua vez.",
            difficulty: .b1,
            category: "Idioms",
            example: "I've done my part, the ball is in your court now."
        ),
        EnglishPhrase(
            text: "Break a leg!",
            translation: "Boa sorte!",
            difficulty: .a1,
            category: "Expressions",
            example: "You're going on stage? Break a leg!"
        )
    ]
}
