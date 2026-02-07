//
//  EnglishPhrase.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 04/01/26.
//

import Foundation


struct EnglishPhrase: Identifiable, Equatable {
    
    let id: UUID
    let text: String
    let translation: String
    let difficulty: DifficultyLevel
    let category: String
    let example: String?
    let audioURL: URL?
    
    init(
        id: UUID = UUID(),
        text: String,
        translation: String,
        difficulty: DifficultyLevel,
        category: String,
        example: String? = nil,
        audioURL: URL? = nil
    ) {
        self.id = id
        self.text = text
        self.translation = translation
        self.difficulty = difficulty
        self.category = category
        self.example = example
        self.audioURL = audioURL
    }
    
    static func == (lhs: EnglishPhrase, rhs: EnglishPhrase) -> Bool {
        lhs.id == rhs.id
    }

}

enum DifficultyLevel: String, CaseIterable {
    case beginner = "Beginner"
    case elementary = "Elementary"
    case intermediate = "Intermediate"
    case upperIntermediate = "Upper-Intermediate"
    case advanced = "Advanced"
}

extension EnglishPhrase {
    static let mockPhrases: [EnglishPhrase] = [
        EnglishPhrase(
            text: "How are you doing today?",
            translation: "Como você está hoje?",
            difficulty: .beginner,
            category: "Greetings",
            example: "A: How are you doing today? B: I'm doing great, thanks for asking!"
        ),
        EnglishPhrase(
            text: "I've been looking forward to this moment.",
            translation: "Eu estava ansioso por este momento.",
            difficulty: .intermediate,
            category: "Emotions",
            example: "I've been looking forward to this moment for weeks."
        ),
        EnglishPhrase(
            text: "Could you lend me a hand?",
            translation: "Você poderia me dar uma mão?",
            difficulty: .elementary,
            category: "Requests",
            example: "Could you lend me a hand with this project?"
        ),
        EnglishPhrase(
            text: "The ball is in your court now.",
            translation: "Agora é a sua vez.",
            difficulty: .intermediate,
            category: "Idioms",
            example: "I've done my part, the ball is in your court now."
        ),
        EnglishPhrase(
            text: "Break a leg!",
            translation: "Boa sorte!",
            difficulty: .beginner,
            category: "Expressions",
            example: "You're going on stage? Break a leg!"
        )
    ]
}
