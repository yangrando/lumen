import Foundation
import AuthenticationServices
import UIKit

enum SocialAuthError: LocalizedError {
    case appleTokenUnavailable
    case googleNotConfigured
    case googleSessionFailed
    case googleMissingIDToken
    case invalidGoogleCallback
    case userCancelled

    var errorDescription: String? {
        switch self {
        case .appleTokenUnavailable:
            return "Apple identity token unavailable."
        case .googleNotConfigured:
            return "Google Sign-In is not configured."
        case .googleSessionFailed:
            return "Google authentication failed."
        case .googleMissingIDToken:
            return "Google did not return an identity token."
        case .invalidGoogleCallback:
            return "Invalid Google callback."
        case .userCancelled:
            return "Authentication cancelled by user."
        }
    }
}

@MainActor
final class SocialAuthService: NSObject {
    static let shared = SocialAuthService()

    private var appleContinuation: CheckedContinuation<String, Error>?
    private var webAuthSession: ASWebAuthenticationSession?

    private override init() {
        super.init()
    }

    func fetchIDToken(for provider: AuthProvider) async throws -> String {
        switch provider {
        case .apple:
            return try await fetchAppleIDToken()
        case .google:
            return try await fetchGoogleIDToken()
        }
    }

    func fetchAppleIDToken() async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            appleContinuation = continuation
            controller.performRequests()
        }
    }

    func fetchGoogleIDToken() async throws -> String {
        guard
            let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String,
            !clientID.isEmpty,
            let redirectURI = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_REDIRECT_URI") as? String,
            !redirectURI.isEmpty
        else {
            throw SocialAuthError.googleNotConfigured
        }

        let callbackScheme =
            (Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CALLBACK_SCHEME") as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedCallbackScheme = (callbackScheme?.isEmpty == false ? callbackScheme : URL(string: redirectURI)?.scheme)
        guard let resolvedCallbackScheme, !resolvedCallbackScheme.isEmpty else {
            throw SocialAuthError.googleNotConfigured
        }

        let state = UUID().uuidString
        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "id_token"),
            URLQueryItem(name: "scope", value: "openid email profile"),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "nonce", value: UUID().uuidString),
            URLQueryItem(name: "prompt", value: "select_account"),
        ]

        guard let authURL = components?.url else {
            throw SocialAuthError.googleSessionFailed
        }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: resolvedCallbackScheme
            ) { callbackURL, error in
                self.webAuthSession = nil

                if let asError = error as? ASWebAuthenticationSessionError,
                   asError.code == .canceledLogin {
                    continuation.resume(throwing: SocialAuthError.userCancelled)
                    return
                }

                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let callbackURL else {
                    continuation.resume(throwing: SocialAuthError.invalidGoogleCallback)
                    return
                }

                do {
                    let idToken = try Self.extractGoogleIDToken(from: callbackURL, expectedState: state)
                    continuation.resume(returning: idToken)
                } catch {
                    continuation.resume(throwing: error)
                }
            }

            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            self.webAuthSession = session
            session.start()
        }
    }

    private static func extractGoogleIDToken(from callbackURL: URL, expectedState: String) throws -> String {
        guard let fragment = callbackURL.fragment else {
            throw SocialAuthError.googleMissingIDToken
        }

        let items = fragment
            .split(separator: "&")
            .map { pair -> (String, String) in
                let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
                let key = parts.first ?? ""
                let value = parts.count > 1 ? parts[1].removingPercentEncoding ?? parts[1] : ""
                return (key, value)
            }

        let payload = Dictionary(uniqueKeysWithValues: items)

        guard payload["state"] == expectedState else {
            throw SocialAuthError.invalidGoogleCallback
        }

        guard let idToken = payload["id_token"], !idToken.isEmpty else {
            throw SocialAuthError.googleMissingIDToken
        }

        return idToken
    }
}

extension SocialAuthService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        Task { @MainActor in
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  !idToken.isEmpty else {
                appleContinuation?.resume(throwing: SocialAuthError.appleTokenUnavailable)
                appleContinuation = nil
                return
            }

            appleContinuation?.resume(returning: idToken)
            appleContinuation = nil
        }
    }

    nonisolated func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        Task { @MainActor in
            if let authError = error as? ASAuthorizationError, authError.code == .canceled {
                appleContinuation?.resume(throwing: SocialAuthError.userCancelled)
            } else {
                appleContinuation?.resume(throwing: error)
            }
            appleContinuation = nil
        }
    }
}

extension SocialAuthService: ASAuthorizationControllerPresentationContextProviding, ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            Self.presentationAnchor()
        }
    }

    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            Self.presentationAnchor()
        }
    }

    @MainActor
    private static func presentationAnchor() -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let window = scene.windows.first(where: \.isKeyWindow) {
                return window
            }
        }
        if let scene = scenes.first {
            return UIWindow(windowScene: scene)
        }
        return UIWindow(frame: .zero)
    }
}
