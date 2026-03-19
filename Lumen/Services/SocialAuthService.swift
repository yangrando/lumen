import Foundation
import AuthenticationServices
import GoogleSignIn
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
            !clientID.isEmpty
        else {
            throw SocialAuthError.googleNotConfigured
        }

        let trimmedServerClientID =
            (Bundle.main.object(forInfoDictionaryKey: "GOOGLE_SERVER_CLIENT_ID") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let serverClientID = trimmedServerClientID?.isEmpty == false ? trimmedServerClientID : nil

        guard let presentingViewController = Self.presentationViewController() else {
            throw SocialAuthError.googleSessionFailed
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID,
            serverClientID: serverClientID
        )
        GIDSignIn.sharedInstance.signOut()

        let result: GIDSignInResult
        do {
            result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
        } catch {
            throw SocialAuthError.googleSessionFailed
        }

        if let idToken = result.user.idToken?.tokenString, !idToken.isEmpty {
            return idToken
        }

        throw SocialAuthError.googleMissingIDToken
    }

    func handleGoogleOpenURL(_ url: URL) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }

    func signOutGoogleIfNeeded() {
        if GIDSignIn.sharedInstance.currentUser != nil {
            GIDSignIn.sharedInstance.signOut()
        }
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

extension SocialAuthService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            Self.presentationAnchor()
        }
    }

    @MainActor
    private static func presentationAnchor() -> ASPresentationAnchor {
        presentationViewController()?.view.window ?? UIWindow(frame: .zero)
    }

    @MainActor
    private static func presentationViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        for scene in scenes {
            if let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController {
                return topViewController(from: root)
            }
        }
        if let root = scenes.first?.windows.first?.rootViewController {
            return topViewController(from: root)
        }
        return nil
    }

    @MainActor
    private static func topViewController(from root: UIViewController) -> UIViewController {
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let navigation = root as? UINavigationController, let visible = navigation.visibleViewController {
            return topViewController(from: visible)
        }
        if let tab = root as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(from: selected)
        }
        return root
    }
}
