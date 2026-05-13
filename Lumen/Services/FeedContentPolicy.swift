import Foundation

/// Encapsula as regras de conteúdo do feed: limites por nível, validação e deduplicação.
/// Separado do ViewModel para ser testável de forma isolada.
struct FeedContentPolicy {

    // MARK: - Limits

    struct Limits {
        let minChars: Int
        let maxChars: Int
        let minWords: Int
        let maxWords: Int
        let preferredSentenceRange: String
    }

    func limits(for level: String) -> Limits {
        let normalized = level
            .lowercased()
            .replacingOccurrences(of: "_", with: "-")
            .replacingOccurrences(of: " ", with: "-")

        if normalized.contains("a1") {
            return Limits(minChars: 12, maxChars: 90,  minWords: 4, maxWords: 10, preferredSentenceRange: "1 short sentence")
        }
        if normalized.contains("a2") {
            return Limits(minChars: 18, maxChars: 110, minWords: 5, maxWords: 12, preferredSentenceRange: "1 short sentence")
        }
        if normalized.contains("b2") {
            return Limits(minChars: 28, maxChars: 140, minWords: 7, maxWords: 16, preferredSentenceRange: "1 short sentence")
        }
        if normalized.contains("c1") {
            return Limits(minChars: 32, maxChars: 160, minWords: 8, maxWords: 18, preferredSentenceRange: "1 short sentence")
        }
        if normalized.contains("c2") {
            return Limits(minChars: 36, maxChars: 180, minWords: 8, maxWords: 20, preferredSentenceRange: "1 short sentence")
        }
        // Default: B1
        return Limits(minChars: 24, maxChars: 130, minWords: 6, maxWords: 14, preferredSentenceRange: "1 short sentence")
    }

    // MARK: - Validation

    func isAcceptable(_ phrase: EnglishPhrase, limits: Limits) -> Bool {
        let text = phrase.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return false }

        let charCount = text.count
        let wordCount = text.split { $0.isWhitespace || $0.isNewline }.count

        // Tolerância aplicada para não descartar frases ligeiramente fora do alvo
        let relaxedMinChars = max(10, limits.minChars - 8)
        let relaxedMaxChars = limits.maxChars + 40
        let relaxedMinWords = max(3, limits.minWords - 2)
        let relaxedMaxWords = limits.maxWords + 6

        return charCount >= relaxedMinChars
            && charCount <= relaxedMaxChars
            && wordCount >= relaxedMinWords
            && wordCount <= relaxedMaxWords
    }

    // MARK: - Deduplication

    func deduplicate(_ items: [EnglishPhrase]) -> [EnglishPhrase] {
        var seen = Set<String>()
        var unique: [EnglishPhrase] = []
        for item in items {
            let key = dedupeKey(for: item)
            guard !key.isEmpty, !seen.contains(key) else { continue }
            seen.insert(key)
            unique.append(item)
        }
        return unique
    }

    func dedupeKey(for phrase: EnglishPhrase) -> String {
        let trimmed = phrase.reelID.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return "reel:\(trimmed.lowercased())"
        }
        return "text:\(normalize(phrase.text))"
    }

    // MARK: - Helpers

    private func normalize(_ text: String) -> String {
        text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
