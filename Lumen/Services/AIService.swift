import Foundation

// MARK: - AI Service for Backend API Integration

class AIService {
    static let shared = AIService()
    
    private let baseURL: String = {
        if let value = Bundle.main.object(forInfoDictionaryKey: "AI_BASE_URL") as? String,
           !value.isEmpty {
            return value
        }
        return "http://localhost:8000/ai/generate"
    }()
    private let logger = Logger.shared
    
    private init() {
        logger.info("AIService initialized")
    }
    
    // MARK: - Generate Phrases
    
    /// Generate English phrases based on user preferences
    /// - Parameters:
    ///   - level: The English proficiency level of the user
    ///   - interests: Array of user interests
    ///   - objectives: Array of user learning objectives
    ///   - count: Number of phrases to generate (default: 5)
    /// - Returns: Array of generated EnglishPhrase objects
    func generatePhrases(
        level: String,
        nativeLanguage: String,
        interests: [String],
        objectives: [String],
        count: Int = 5,
        excludedTexts: [String] = [],
        minWordsPerCard: Int = 24,
        maxWordsPerCard: Int = 90,
        minCharactersPerCard: Int = 120,
        maxCharactersPerCard: Int = 560,
        preferredSentenceRange: String = "2 to 4 sentences"
    ) async throws -> [EnglishPhrase] {
        logger.info("Starting phrase generation - Level: \(level), Interests: \(interests.joined(separator: ", ")), Count: \(count)")
        
        let prompt = buildPrompt(
            level: level,
            nativeLanguage: nativeLanguage,
            interests: interests,
            objectives: objectives,
            count: count,
            excludedTexts: excludedTexts,
            minWordsPerCard: minWordsPerCard,
            maxWordsPerCard: maxWordsPerCard,
            minCharactersPerCard: minCharactersPerCard,
            maxCharactersPerCard: maxCharactersPerCard,
            preferredSentenceRange: preferredSentenceRange
        )
        
        logger.debug("Generated prompt for API call")
        
        let response = try await callOpenAI(
            prompt: prompt,
            task: "generate_phrases",
            meta: [
                "count": count,
                "cefr_level": level,
                "native_language": nativeLanguage,
                "enforce_translation_language": true,
                "min_words_per_card": minWordsPerCard,
                "max_words_per_card": maxWordsPerCard,
                "min_chars_per_card": minCharactersPerCard,
                "max_chars_per_card": maxCharactersPerCard
            ]
        )
        logger.debug("Received response from OpenAI API")
        
        let phrases = try parsePhrases(from: response)
        logger.success("Successfully parsed \(phrases.count) phrases")
        
        return phrases
    }

    func askAboutPhrase(
        phrase: String,
        question: String,
        userLevel: String,
        nativeLanguage: String
    ) async throws -> String {
        let prompt = """
        You are assisting an English learner at \(userLevel) level.

        Phrase:
        "\(phrase)"

        User question:
        "\(question)"

        Respond in \(nativeLanguage) with:
        1) A direct answer to the user's question.
        2) A short explanation with context.
        3) One extra example sentence in English with translation in \(nativeLanguage).

        Keep it practical and easy to understand.
        """

        return try await callOpenAI(prompt: prompt, task: "answer_doubt")
    }
    
    // MARK: - Get AI Feedback
    
    /// Get AI feedback for a specific phrase
    /// - Parameters:
    ///   - phrase: The English phrase to get feedback on
    ///   - userLevel: The user's English proficiency level
    /// - Returns: Feedback string from the AI
    func getPhraseFeedback(
        phrase: String,
        userLevel: String
    ) async throws -> String {
        logger.info("Requesting feedback for phrase: '\(phrase)' at level: \(userLevel)")
        
        let prompt = """
        The user is learning English at \(userLevel) level.
        
        They asked about this phrase: "\(phrase)"
        
        Please provide:
        1. A brief explanation of the phrase (2-3 sentences)
        2. When and how to use it
        3. Similar phrases they could use
        
        Keep the explanation simple and appropriate for their level.
        """
        
        let response = try await callOpenAI(prompt: prompt, task: "explain_phrase")
        logger.success("Feedback received for phrase: '\(phrase)'")
        
        return response
    }
    
    // MARK: - Translate Phrase
    
    /// Translate an English phrase to the requested language
    /// - Parameters:
    ///   - phrase: The English phrase to translate
    ///   - targetLanguage: Desired translation language
    /// - Returns: Translated phrase
    func translatePhrase(_ phrase: String, targetLanguage: String = "Portuguese (Brazil)") async throws -> String {
        logger.info("Translating phrase: '\(phrase)'")
        
        let prompt = "Translate this English phrase to \(targetLanguage). Only provide the translation, nothing else:\n\n\(phrase)"
        
        let response = try await callOpenAI(
            prompt: prompt,
            task: "translate_phrase",
            meta: ["target_language": targetLanguage]
        )
        let translation = response.trimmingCharacters(in: .whitespaces)
        
        logger.success("Translation completed: '\(phrase)' -> '\(translation)'")
        
        return translation
    }
    
    // MARK: - Private Methods
    
    private func buildPrompt(
        level: String,
        nativeLanguage: String,
        interests: [String],
        objectives: [String],
        count: Int,
        excludedTexts: [String],
        minWordsPerCard: Int,
        maxWordsPerCard: Int,
        minCharactersPerCard: Int,
        maxCharactersPerCard: Int,
        preferredSentenceRange: String
    ) -> String {
        let interestsStr = interests.joined(separator: ", ")
        let objectivesStr = objectives.joined(separator: ", ")
        let excludedList = excludedTexts.prefix(30).map { "- \($0)" }.joined(separator: "\n")
        let exclusionBlock = excludedList.isEmpty ? "" : """
        
        Do not repeat these existing cards (or near-duplicates):
        \(excludedList)
        """
        
        return """
        Generate \(count) English learning cards for someone at CEFR \(level) level.

        User Interests: \(interestsStr)
        Learning Objectives: \(objectivesStr)

        Content mix requirements:
        - Prioritize relevant content, not generic motivational lines.
        - Every card MUST include at least one concrete anchor:
          a) a historical fact with year/date,
          b) a real event, person, or place,
          c) a cultural curiosity with context,
          d) a music reference identifying song and artist.
        - Length target per card:
          a) \(minWordsPerCard)-\(maxWordsPerCard) words,
          b) \(minCharactersPerCard)-\(maxCharactersPerCard) characters.
        - Preferred structure: \(preferredSentenceRange).
        - Keep each card coherent, factual, and useful for real English learning.
        - Ensure cards are diverse in topic and wording; avoid repetition.
        - For music-related cards: do not provide long copyrighted lyrics; if needed, use an excerpt with at most 8 words and focus on explanation/context.
        \(exclusionBlock)

        For each card, provide:
        1. The English text (natural and useful; follow the target length/structure above)
        2. Translation in \(nativeLanguage)
        3. Category (e.g., "Business", "Technology", "History", "Science", "Travel", "Culture")
        4. Difficulty level (must exactly match the CEFR input level: \(level))
        
        Format your response as a JSON array with objects containing EXACTLY these keys:
        - "text": the English phrase
        - "translation": the translation in \(nativeLanguage)
        - "category": the category
        - "difficulty": the difficulty level
        
        Return ONLY the JSON array, no other text, no markdown, no code fences.
        
        Example format:
        [
            {
                "text": "How are you doing today?",
                "translation": "Como você está hoje?",
                "category": "Greetings",
                "difficulty": "\(level)"
            }
        ]
        """
    }
    
    private func callOpenAI(prompt: String, task: String?, meta: [String: Any]? = nil) async throws -> String {
        logger.debug("Preparing backend AI request")
        let accessToken = await MainActor.run { SessionService.shared.accessToken }
        guard let accessToken else {
            throw AIServiceError.unauthenticated
        }
        
        // Prepare the request
        guard let url = URL(string: baseURL) else {
            logger.error("Invalid API URL: \(baseURL)")
            throw AIServiceError.networkError("Invalid API URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 90
        
        logger.logAPIRequest(url: baseURL, method: "POST")
        
        // Prepare the body
        var body: [String: Any] = [
            "prompt": prompt,
            "temperature": 0.7,
            "max_tokens": 1200
        ]
        if let task {
            body["task"] = task
        }
        if let meta {
            body["meta"] = meta
        }
        
        logger.logJSON(body, title: "Request Body")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Make the request
        logger.debug("Sending request to backend API...")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Log response
        if let httpResponse = response as? HTTPURLResponse {
            logger.logAPIResponse(statusCode: httpResponse.statusCode)
            
            // Log response body
            if let responseString = String(data: data, encoding: .utf8) {
                logger.debug("Response Body: \(responseString)")
            }
        }
        
        // Check for HTTP errors
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let errorMessage = "Invalid response from server (Status: \(statusCode))"
            logger.error(errorMessage)
            
            // Try to extract error message from response
            if let errorResponse = try? JSONDecoder().decode(BackendErrorResponse.self, from: data) {
                logger.error("Backend Error: \(errorResponse.detail)")
            }
            
            throw AIServiceError.networkError(errorMessage)
        }
        
        // Decode the response
        logger.debug("Decoding backend response...")
        let decodedResponse = try JSONDecoder().decode(BackendResponse.self, from: data)
        
        let content = decodedResponse.text
        if content.isEmpty {
            logger.error("Could not extract content from backend response")
            throw AIServiceError.decodingError("Could not extract content from response")
        }
        
        logger.success("Successfully decoded backend response")
        return content
    }
    
    // MARK: - Parse Phrases from JSON Response
    
    private func parsePhrases(from jsonString: String) throws -> [EnglishPhrase] {
        logger.debug("Parsing phrases from JSON response")
        
        // Remove markdown code blocks if present
        var cleanedJson = jsonString
        if cleanedJson.contains("```json") {
            logger.debug("Removing ```json markdown blocks")
            cleanedJson = cleanedJson.replacingOccurrences(of: "```json", with: "")
            cleanedJson = cleanedJson.replacingOccurrences(of: "```", with: "")
        } else if cleanedJson.contains("```") {
            logger.debug("Removing ``` markdown blocks")
            cleanedJson = cleanedJson.replacingOccurrences(of: "```", with: "")
        }
        
        cleanedJson = cleanedJson.trimmingCharacters(in: .whitespaces)
        logger.debug("Cleaned JSON: \(cleanedJson)")
        
        guard let data = cleanedJson.data(using: .utf8) else {
            logger.error("Could not convert JSON string to data")
            throw AIServiceError.decodingError("Could not convert response to data")
        }
        
        let phraseResponses = try JSONDecoder().decode([PhraseResponse].self, from: data)
        logger.info("Decoded \(phraseResponses.count) phrase responses from JSON")
        
        let phrases = phraseResponses.map { phraseResponse in
            // Convert String difficulty to DifficultyLevel enum
            let difficultyLevel = DifficultyLevel(label: phraseResponse.difficulty)
            
            return EnglishPhrase(
                text: phraseResponse.text,
                translation: phraseResponse.translation,
                difficulty: difficultyLevel,
                category: phraseResponse.category
            )
        }
        
        logger.success("Successfully parsed \(phrases.count) EnglishPhrase objects")
        return phrases
    }
}

// MARK: - Models for API Communication

struct BackendResponse: Codable {
    let text: String
}

struct BackendErrorResponse: Codable {
    let detail: String
}

struct PhraseResponse: Codable {
    let text: String
    let translation: String
    let category: String
    let difficulty: String
}

// MARK: - Error Handling

enum AIServiceError: LocalizedError {
    case networkError(String)
    case decodingError(String)
    case invalidAPIKey
    case unauthenticated
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network Error: \(message)"
        case .decodingError(let message):
            return "Decoding Error: \(message)"
        case .invalidAPIKey:
            return "Invalid API Key"
        case .unauthenticated:
            return "Authentication required. Please sign in again."
        }
    }
}
