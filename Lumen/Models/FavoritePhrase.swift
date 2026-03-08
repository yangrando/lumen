import Foundation
import SwiftData

@Model
final class FavoritePhrase {
    var text: String
    var translation: String
    var category: String
    var difficulty: String
    var dateSaved: Date

    init(
        text: String,
        translation: String,
        category: String,
        difficulty: String,
        dateSaved: Date = .now
    ) {
        self.text = text
        self.translation = translation
        self.category = category
        self.difficulty = difficulty
        self.dateSaved = dateSaved
    }
}
