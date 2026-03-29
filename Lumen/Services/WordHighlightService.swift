import Foundation

struct HighlightedWord: Identifiable, Equatable {
    let id: String
    let rawToken: String
    let normalizedWord: String
    let isHighlighted: Bool
}

struct WordDetail: Identifiable, Equatable {
    var id: String { word.lowercased() }
    let word: String
    let phonetic: String
    let translation: String
    let exampleSentence: String
}

actor WordHighlightService {
    static let shared = WordHighlightService()

    private var detailsCache: [String: WordDetail] = [:]
    private let commonWords: Set<String> = [
        "the","a","an","and","or","but","if","to","of","in","on","at","for","with","from","by","about","into",
        "is","are","was","were","be","been","being","it","this","that","these","those","as","than","then","so",
        "we","you","they","he","she","i","my","our","your","their","his","her","its","do","does","did","can",
        "could","would","should","will","shall","have","has","had","not","no","yes","very","more","most"
    ]
    private let translationDictionary: [String: String] = [
        "vocabulary": "vocabulário",
        "excellent": "excelente",
        "widely": "amplamente",
        "technology": "tecnologia",
        "research": "pesquisa",
        "business": "negócios",
        "improve": "melhorar",
        "reading": "leitura",
        "speaking": "fala",
        "confidence": "confiança",
        "traveling": "viajando",
        "experience": "experiência",
        "perspective": "perspectiva"
    ]

    nonisolated static func highlightedTokens(for phrase: EnglishPhrase) -> [HighlightedWord] {
        let threshold: Int
        switch phrase.difficulty {
        case .a1: threshold = 9
        case .a2: threshold = 10
        case .b1: threshold = 8
        case .b2: threshold = 7
        case .c1, .c2: threshold = 6
        }

        return phrase.text.split(separator: " ").enumerated().map { index, token in
            let rawToken = String(token)
            let normalized = rawToken
                .lowercased()
                .replacingOccurrences(of: #"^[^a-zA-Z]+|[^a-zA-Z]+$"#, with: "", options: .regularExpression)
            let commonWords: Set<String> = [
                "the","a","an","and","or","but","if","to","of","in","on","at","for","with","from","by","about","into",
                "is","are","was","were","be","been","being","it","this","that","these","those","as","than","then","so",
                "we","you","they","he","she","i","my","our","your","their","his","her","its","do","does","did","can",
                "could","would","should","will","shall","have","has","had","not","no","yes","very","more","most"
            ]
            let shouldHighlight = normalized.count >= threshold && !commonWords.contains(normalized)
            return HighlightedWord(
                id: "\(index)|\(rawToken)|\(normalized)",
                rawToken: rawToken,
                normalizedWord: normalized,
                isHighlighted: shouldHighlight
            )
        }
    }

    func detail(for word: String, phrase: EnglishPhrase, nativeLanguage: String) async -> WordDetail {
        let cacheKey = "\(nativeLanguage.lowercased())|\(word.lowercased())"
        if let cached = detailsCache[cacheKey] {
            return cached
        }
        let detail = WordDetail(
            word: word,
            phonetic: makePseudoPhonetic(for: word),
            translation: makeTranslation(for: word, nativeLanguage: nativeLanguage),
            exampleSentence: phrase.text
        )
        detailsCache[cacheKey] = detail
        return detail
    }

    private func makeTranslation(for word: String, nativeLanguage: String) -> String {
        let normalized = word.lowercased()
        if nativeLanguage.lowercased().contains("portugu") {
            return translationDictionary[normalized] ?? normalized
        }
        return normalized
    }

    private func makePseudoPhonetic(for word: String) -> String {
        let normalized = word.lowercased()
            .replacingOccurrences(of: "tion", with: "shun")
            .replacingOccurrences(of: "ough", with: "oh")
            .replacingOccurrences(of: "ph", with: "f")
            .replacingOccurrences(of: "th", with: "th")
            .replacingOccurrences(of: "qu", with: "kw")
        return "/\(normalized)/"
    }
}
