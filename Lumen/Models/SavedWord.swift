import Foundation
import SwiftData

@Model
final class SavedWord {
    var userID: String?
    var word: String
    var phonetic: String
    var translation: String
    var exampleSentence: String
    var createdAt: Date

    init(
        userID: String? = nil,
        word: String,
        phonetic: String,
        translation: String,
        exampleSentence: String,
        createdAt: Date = .now
    ) {
        self.userID = userID
        self.word = word
        self.phonetic = phonetic
        self.translation = translation
        self.exampleSentence = exampleSentence
        self.createdAt = createdAt
    }
}
