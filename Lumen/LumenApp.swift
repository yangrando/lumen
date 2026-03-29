//
//  LumenApp.swift
//  Lumen
//
//  Created by Yan Felipe Grando on 26/12/25.
//

import SwiftUI
import SwiftData
import GoogleSignIn

@main
struct LumenApp: App {
    @State private var showSplash = true
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                OnboardingView()
                    .opacity(showSplash ? 0 : 1)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .task {
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSplash = false
                }
            }
            .onOpenURL { url in
                _ = SocialAuthService.shared.handleGoogleOpenURL(url)
            }
            .task {
                await TrackingService.shared.flushIfNeeded(force: true)
            }
            .onChange(of: scenePhase) { _, newPhase in
                Task {
                    await TrackingService.shared.handleScenePhaseChange(newPhase)
                }
            }
        }
        .modelContainer(for: [FavoritePhrase.self, SavedWord.self])
    }
}
