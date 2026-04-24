import Foundation

enum NativeLanguageLocalization {
    private static let preferenceKey = "lumen_preferred_native_language"
    static let didChangeNotification = Notification.Name("lumen.nativeLanguage.didChange")

    private struct SupportedLanguage {
        let preferenceLabel: String
        let localizationCode: String
        let localePrefixes: [String]
    }

    private static let supportedLanguages: [SupportedLanguage] = [
        .init(preferenceLabel: "Portuguese (Brazil)", localizationCode: "pt-BR", localePrefixes: ["pt-BR", "pt"]),
        .init(preferenceLabel: "Spanish", localizationCode: "es", localePrefixes: ["es"]),
        .init(preferenceLabel: "English", localizationCode: "en", localePrefixes: ["en"]),
        .init(preferenceLabel: "French", localizationCode: "fr", localePrefixes: ["fr"]),
        .init(preferenceLabel: "German", localizationCode: "de", localePrefixes: ["de"]),
        .init(preferenceLabel: "Italian", localizationCode: "it", localePrefixes: ["it"]),
        .init(preferenceLabel: "Russian", localizationCode: "ru", localePrefixes: ["ru"]),
        .init(preferenceLabel: "Japanese", localizationCode: "ja", localePrefixes: ["ja"]),
        .init(preferenceLabel: "Korean", localizationCode: "ko", localePrefixes: ["ko"]),
        .init(preferenceLabel: "Chinese (Simplified)", localizationCode: "zh-Hans", localePrefixes: ["zh-Hans", "zh-CN", "zh"])
    ]

    static func savePreferredNativeLanguage(_ value: String, notify: Bool = true) {
        guard preferredNativeLanguage() != value else { return }
        UserDefaults.standard.set(value, forKey: preferenceKey)
        if notify {
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        }
    }

    static func clearPreferredNativeLanguage() {
        guard UserDefaults.standard.object(forKey: preferenceKey) != nil else { return }
        UserDefaults.standard.removeObject(forKey: preferenceKey)
        NotificationCenter.default.post(name: didChangeNotification, object: nil)
    }

    static func localizedString(forKey key: String, fallback: String = "") -> String {
        let languageCode = resolvedLanguageCode()
        let bundle = localizedBundle(for: languageCode)

        if let bundle {
            let localized = NSLocalizedString(key, bundle: bundle, comment: "")
            if localized != key {
                return localized
            }
        }

        let systemLocalized = NSLocalizedString(key, comment: "")
        if systemLocalized != key {
            return systemLocalized
        }
        return fallback.isEmpty ? key : fallback
    }

    static func preferredNativeLanguage() -> String {
        if let saved = UserDefaults.standard.string(forKey: preferenceKey),
           supportedLanguage(forPreferenceLabel: saved) != nil {
            return saved
        }
        return devicePreferredNativeLanguage()
    }

    private static func resolvedLanguageCode() -> String {
        supportedLanguage(forPreferenceLabel: preferredNativeLanguage())?.localizationCode ?? "en"
    }

    private static func devicePreferredNativeLanguage() -> String {
        for preferredIdentifier in Locale.preferredLanguages {
            let lowercased = preferredIdentifier.lowercased()
            if let match = supportedLanguages.first(where: { language in
                language.localePrefixes.contains { prefix in
                    let normalizedPrefix = prefix.lowercased()
                    return lowercased == normalizedPrefix || lowercased.hasPrefix(normalizedPrefix + "-")
                }
            }) {
                return match.preferenceLabel
            }
        }
        return "English"
    }

    private static func supportedLanguage(forPreferenceLabel label: String) -> SupportedLanguage? {
        supportedLanguages.first { $0.preferenceLabel.caseInsensitiveCompare(label) == .orderedSame }
    }

    private static func localizedBundle(for languageCode: String) -> Bundle? {
        let candidates: [String]
        switch languageCode {
        case "pt-BR":
            candidates = ["pt-BR", "pt"]
        case "es":
            candidates = ["es"]
        case "fr":
            candidates = ["fr", "en"]
        case "de":
            candidates = ["de", "en"]
        case "it":
            candidates = ["it", "en"]
        case "ru":
            candidates = ["ru", "en"]
        case "ja":
            candidates = ["ja", "en"]
        case "ko":
            candidates = ["ko", "en"]
        case "zh-Hans":
            candidates = ["zh-Hans", "zh", "en"]
        default:
            candidates = [languageCode, "en"]
        }

        for candidate in candidates {
            if let path = Bundle.main.path(forResource: candidate, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }
        return nil
    }
}
