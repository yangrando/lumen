import Foundation

enum UserFacingMessageMapper {
    static func localizedErrorMessage(for error: Error) -> String {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return LocalizedStrings.commonErrorTimeout
            case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
                return LocalizedStrings.commonErrorConnection
            default:
                break
            }
        }

        if let lumenError = error as? LumenError {
            switch lumenError {
            case .unauthenticated:
                return LocalizedStrings.commonErrorUnauthenticated
            case .timeout:
                return LocalizedStrings.commonErrorTimeout
            case .network(let message):
                return message.map { normalizeBackendMessage($0) } ?? LocalizedStrings.commonErrorConnection
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
            case .backgroundUnavailable, .invalidBackgroundURL:
                return LocalizedStrings.commonErrorGeneric
            case .generic(let message):
                return message ?? LocalizedStrings.commonErrorGeneric
            }
        }

        return normalizeBackendMessage(error.localizedDescription)
    }

    static func errorFeedback(_ error: Error) -> AppFeedbackMessage {
        AppFeedbackMessage(
            title: LocalizedStrings.feedbackErrorTitle,
            message: localizedErrorMessage(for: error),
            tone: .error
        )
    }

    static func successFeedback(message: String) -> AppFeedbackMessage {
        AppFeedbackMessage(
            title: LocalizedStrings.feedbackSuccessTitle,
            message: message,
            tone: .success
        )
    }

    private static func normalizeBackendMessage(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowered = trimmed.lowercased()

        if lowered.contains("timed out") || lowered.contains("timeout") {
            return LocalizedStrings.commonErrorTimeout
        }
        if lowered.contains("not connected") || lowered.contains("network") || lowered.contains("internet connection") {
            return LocalizedStrings.commonErrorConnection
        }
        if lowered.contains("quota") || lowered.contains("resource_exhausted") || lowered.contains("rate limit") || lowered.contains("retry in") {
            return LocalizedStrings.errorQuotaExceeded
        }
        if lowered.hasPrefix("network error:") {
            let cleaned = trimmed.replacingOccurrences(of: "Network Error:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanedLowered = cleaned.lowercased()
            if cleanedLowered.contains("quota") || cleanedLowered.contains("resource_exhausted") || cleanedLowered.contains("rate limit") || cleanedLowered.contains("retry in") {
                return LocalizedStrings.errorQuotaExceeded
            }
            return cleaned.isEmpty ? LocalizedStrings.commonErrorGeneric : cleaned
        }
        if lowered.hasPrefix("decoding error:") {
            return LocalizedStrings.commonErrorGeneric
        }
        return trimmed.isEmpty ? LocalizedStrings.commonErrorGeneric : trimmed
    }
}
