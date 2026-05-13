import Foundation

/// Centralized error type for all Lumen services.
/// Provides localized descriptions mapped to the app's translation files.
enum LumenError: LocalizedError {

    // MARK: - Network
    case network(String? = nil)
    case timeout
    case unauthenticated

    // MARK: - Parsing
    case decoding(String? = nil)

    // MARK: - AI
    case invalidAPIKey

    // MARK: - Social Auth
    case appleTokenUnavailable
    case googleNotConfigured
    case googleAuthFailed
    case userCancelled

    // MARK: - Background
    case backgroundUnavailable
    case invalidBackgroundURL

    // MARK: - Generic
    case generic(String? = nil)

    var errorDescription: String? {
        switch self {
        case .network(let message):
            return message ?? LocalizedStrings.commonErrorConnection
        case .timeout:
            return LocalizedStrings.commonErrorTimeout
        case .unauthenticated:
            return LocalizedStrings.commonErrorUnauthenticated
        case .decoding:
            return LocalizedStrings.commonErrorGeneric
        case .invalidAPIKey:
            return LocalizedStrings.commonErrorGeneric
        case .appleTokenUnavailable:
            return LocalizedStrings.authAppleTokenUnavailable
        case .googleNotConfigured:
            return LocalizedStrings.authGoogleNotConfigured
        case .googleAuthFailed:
            return LocalizedStrings.authGoogleFailed
        case .userCancelled:
            return LocalizedStrings.authCancelled
        case .backgroundUnavailable:
            return LocalizedStrings.commonErrorGeneric
        case .invalidBackgroundURL:
            return LocalizedStrings.commonErrorGeneric
        case .generic(let message):
            return message ?? LocalizedStrings.commonErrorGeneric
        }
    }
}
