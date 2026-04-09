import Foundation

enum NativeLanguageLocalization {
    private static let preferenceKey = "lumen_preferred_native_language"

    static func savePreferredNativeLanguage(_ value: String) {
        UserDefaults.standard.set(value, forKey: preferenceKey)
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
        UserDefaults.standard.string(forKey: preferenceKey) ?? "English"
    }

    private static func resolvedLanguageCode() -> String {
        let value = (UserDefaults.standard.string(forKey: preferenceKey) ?? "").lowercased()
        if value.contains("portugu") {
            return "pt-BR"
        }
        if value.contains("spanish") || value.contains("espan") {
            return "es"
        }
        return "en"
    }

    private static func localizedBundle(for languageCode: String) -> Bundle? {
        let candidates: [String]
        switch languageCode {
        case "pt-BR":
            candidates = ["pt-BR", "pt"]
        case "es":
            candidates = ["es"]
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
