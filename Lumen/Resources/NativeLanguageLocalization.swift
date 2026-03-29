import Foundation

enum NativeLanguageLocalization {
    private static let preferenceKey = "lumen_preferred_native_language"

    static func savePreferredNativeLanguage(_ value: String) {
        UserDefaults.standard.set(value, forKey: preferenceKey)
    }

    static func localizedString(forKey key: String, fallback: String = "") -> String {
        let languageCode = resolvedLanguageCode()
        guard
            let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            let localized = NSLocalizedString(key, comment: "")
            return localized == key ? fallback : localized
        }

        let localized = NSLocalizedString(key, bundle: bundle, comment: "")
        if localized == key {
            return fallback.isEmpty ? NSLocalizedString(key, comment: "") : fallback
        }
        return localized
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
}
