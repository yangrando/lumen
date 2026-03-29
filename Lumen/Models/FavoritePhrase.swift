import Foundation
import SwiftData

@Model
final class FavoritePhrase {
    var reelID: String
    var userID: String?
    var text: String
    var translation: String
    var category: String
    var difficulty: String
    var dateSaved: Date
    var isPendingSync: Bool
    var lastSyncedAt: Date?

    init(
        reelID: String,
        userID: String? = nil,
        text: String,
        translation: String,
        category: String,
        difficulty: String,
        dateSaved: Date = .now,
        isPendingSync: Bool = false,
        lastSyncedAt: Date? = nil
    ) {
        self.reelID = reelID
        self.userID = userID
        self.text = text
        self.translation = translation
        self.category = category
        self.difficulty = difficulty
        self.dateSaved = dateSaved
        self.isPendingSync = isPendingSync
        self.lastSyncedAt = lastSyncedAt
    }
}
