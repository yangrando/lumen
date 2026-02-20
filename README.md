# Lumen

Lumen is an iOS app focused on English learning through short, practical phrases generated from user onboarding preferences.

This public repository contains the iOS client code and public API contract docs. Backend runtime, provider credentials, and production infrastructure are intentionally kept private.

## Product Scope

- Collect learner profile during onboarding (level, interests, objectives).
- Generate personalized English phrases with PT-BR translation.
- Show phrases in a vertical feed experience.
- Let users ask for phrase explanations and usage guidance.

## Architecture

The app follows a simple layered structure:

1. `Views` (SwiftUI): UI rendering and user interactions.
2. `ViewModels` (`ObservableObject`): state management and async orchestration.
3. `Services`: networking and logging.
4. `Models`: domain types and enums for onboarding + phrase data.

Main flow:

1. `OnboardingView` collects user profile.
2. `FeedViewModel` requests generated content from `AIService`.
3. `AIService` calls backend endpoint `/ai/generate`.
4. Backend returns text payload; app parses it into `EnglishPhrase`.
5. `FeedView` renders phrases in a vertically paged UI.

## Repository Structure

```text
Lumen/
├── Lumen/                         # iOS app source
│   ├── Views/                     # Screen composition
│   ├── ViewModels/                # UI state + async calls
│   ├── Services/                  # API client and logger
│   ├── Models/                    # Domain model definitions
│   ├── Components/                # Reusable UI pieces
│   └── Resources/                 # Localization, colors, fonts
├── docs/
│   └── api.md                     # Public backend API contract
├── SECURITY.md                    # Security publication policy
└── .github/workflows/security.yml # Secret/dependency checks
```

## App Layers and Core Files

- App entrypoint: `/Users/yanfelipegrando/Documents/GitHub/Lumen/Lumen/LumenApp.swift`
- Onboarding state machine: `/Users/yanfelipegrando/Documents/GitHub/Lumen/Lumen/Views/OnboardingView.swift`
- Feed state and async logic: `/Users/yanfelipegrando/Documents/GitHub/Lumen/Lumen/ViewModels/FeedViewModel.swift`
- API integration client: `/Users/yanfelipegrando/Documents/GitHub/Lumen/Lumen/Services/AIService.swift`
- Logging utility: `/Users/yanfelipegrando/Documents/GitHub/Lumen/Lumen/Services/Logger.swift`
- Public API contract: `/Users/yanfelipegrando/Documents/GitHub/Lumen/docs/api.md`

## Data and Request Flow

### Phrase generation

1. `FeedViewModel.loadPhrases()` triggers generation.
2. `AIService.generatePhrases()` builds prompt with:
   - `level`
   - `interests`
   - `objectives`
3. Service sends `POST /ai/generate` with task `generate_phrases`.
4. Backend returns JSON text payload.
5. App parses response to `[EnglishPhrase]`.
6. On failure, app falls back to local mock phrases.

### Phrase explanation

1. User taps "Ask AI" in phrase card.
2. `FeedViewModel.getPhraseFeedback(...)` calls `AIService.getPhraseFeedback(...)`.
3. Service sends task `explain_phrase`.
4. Backend returns explanation text.

### Translation

1. `FeedViewModel.translatePhrase(...)` calls `AIService.translatePhrase(...)`.
2. Service sends task `translate_phrase`.
3. Backend returns translated text.

## Libraries and Frameworks

No third-party iOS dependency manager is currently used in this repository.

Apple frameworks:

- `SwiftUI` for UI composition and app lifecycle.
- `Foundation` for networking and JSON handling.
- `Combine` for reactive state (`@Published`).
- `UIKit` interop for vertical paging (`UIPageViewController` wrapper).

Backend references are documented in `/Users/yanfelipegrando/Documents/GitHub/Lumen/docs/api.md`, but backend code is private.

## Environment Configuration

The app reads API base URL from `Info.plist` key `AI_BASE_URL`, injected from build settings.

- Debug uses local network backend URL.
- Release uses production backend URL placeholder.

Relevant files:

- `/Users/yanfelipegrando/Documents/GitHub/Lumen/Lumen/Info.plist`
- `/Users/yanfelipegrando/Documents/GitHub/Lumen/Lumen.xcodeproj/project.pbxproj`

## Security Model for Public Source

- Client repository is public by design.
- Secrets and provider keys are never stored in app code.
- App communicates only with backend.
- Provider credentials and orchestration remain server-side.

Read publication rules in `/Users/yanfelipegrando/Documents/GitHub/Lumen/SECURITY.md`.

## Local Development (iOS)

1. Open `/Users/yanfelipegrando/Documents/GitHub/Lumen/Lumen.xcodeproj`.
2. Select target `Lumen`.
3. Run with Debug configuration.
4. Ensure `AI_BASE_URL` points to a reachable backend instance.

For simulator, `localhost` may be used if backend is running on the same machine.
For physical device, use the machine LAN IP.

## Current Limitations

- User onboarding selections are not yet persisted.
- Feed currently initializes with default fallback preferences in `FeedViewModel`.
- Saved phrases are in-memory only (`TODO` for local persistence).
- "Ask AI" currently logs output and needs full in-app explanation UI.

## Roadmap Direction

- Persist onboarding and saved phrases.
- Add robust error handling UX and traceability (`request_id` surfacing).
- Expand AI-assisted interactions directly inside phrase consumption flow.
- Add stronger test coverage for parsing, networking, and view model behavior.
