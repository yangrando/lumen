import SwiftUI
import SwiftData

struct SavedPhrasesView: View {
    enum DifficultyFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case basic = "A1-A2"
        case independent = "B1-B2"
        case proficient = "C1-C2"

        var id: String { rawValue }
    }

    @Query(sort: \FavoritePhrase.dateSaved, order: .reverse) private var favorites: [FavoritePhrase]
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var audioService = AudioService.shared
    @StateObject private var sessionService = SessionService.shared
    @State private var selectedCategory = "All"
    @State private var selectedDifficulty: DifficultyFilter = .all
    @State private var searchText = ""
    @State private var feedbackMessage: AppFeedbackMessage?

    init() {}

    private var currentUserID: String? {
        sessionService.currentUser?.sub
    }

    private var scopedFavorites: [FavoritePhrase] {
        guard let currentUserID else {
            return favorites.filter { $0.userID == nil }
        }
        return favorites.filter { $0.userID == currentUserID }
    }

    private var categories: [String] {
        let dynamic = Set(scopedFavorites.map(\.category).filter { !$0.isEmpty })
        return ["All"] + dynamic.sorted()
    }

    private var filteredPhrases: [FavoritePhrase] {
        scopedFavorites.filter { phrase in
            let categoryMatch = selectedCategory == "All" || phrase.category == selectedCategory
            let difficultyMatch: Bool
            switch selectedDifficulty {
            case .all:
                difficultyMatch = true
            case .basic:
                difficultyMatch = ["a1", "a2", "beginner", "elementary"].contains(phrase.difficulty.lowercased())
            case .independent:
                difficultyMatch = ["b1", "b2", "intermediate", "upper-intermediate", "upperintermediate"].contains(phrase.difficulty.lowercased())
            case .proficient:
                difficultyMatch = ["c1", "c2", "advanced", "proficient"].contains(phrase.difficulty.lowercased())
            }

            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let searchMatch = query.isEmpty ||
                phrase.text.lowercased().contains(query) ||
                phrase.translation.lowercased().contains(query)

            return categoryMatch && difficultyMatch && searchMatch
        }
    }

    var body: some View {
        ZStack {
            LumenColors.navyDark
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: iconName(for: category))
                                    Text(category)
                                        .lineLimit(1)
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .foregroundStyle(selectedCategory == category ? .white : LumenColors.textSecondary)
                                .background(
                                    selectedCategory == category
                                    ? AnyShapeStyle(LinearGradient.primaryGradient)
                                    : AnyShapeStyle(Color.clear)
                                )
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                }

                Picker("Difficulty", selection: $selectedDifficulty) {
                    ForEach(DifficultyFilter.allCases) { difficulty in
                        Text(difficulty.rawValue).tag(difficulty)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)

                if filteredPhrases.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "books.vertical")
                            .font(.system(size: 48))
                            .foregroundStyle(LumenColors.textSecondary)

                        Text(LocalizedStrings.libraryEmptyTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)

                        Text(LocalizedStrings.libraryEmptyDescription)
                            .font(.system(size: 14))
                            .foregroundStyle(LumenColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, 24)
                } else {
                    List {
                        ForEach(filteredPhrases) { phrase in
                            SavedPhraseRow(
                                phrase: phrase,
                                isPlaying: audioService.currentlyPlayingPhraseID == audioPhraseID(for: phrase),
                                onPlayAudio: {
                                    toggleAudio(for: phrase)
                                }
                            )
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deletePhrases)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(.top, 12)
        }
        .navigationTitle(LocalizedStrings.feedSavedPhrases)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: LocalizedStrings.librarySearchPlaceholder)
        .onAppear {
            Task {
                await sessionService.ensureCurrentUserLoaded()
                await syncSavedReels()
                await TrackingService.shared.startSession(.review, metadata: ["source": .string("saved_phrases")])
            }
        }
        .onDisappear {
            audioService.stop()
            Task {
                await TrackingService.shared.endSession(.review, metadata: ["reason": .string("saved_phrases_closed")])
            }
        }
        .appFeedbackBanner($feedbackMessage)
    }

    private func iconName(for category: String) -> String {
        switch category.lowercased() {
        case "all":
            return "square.grid.2x2"
        case "business":
            return "briefcase.fill"
        case "technology":
            return "desktopcomputer"
        case "travel":
            return "airplane"
        case "greetings":
            return "hand.wave.fill"
        default:
            return "folder.fill"
        }
    }

    private func deletePhrases(at offsets: IndexSet) {
        Task {
            await sessionService.ensureCurrentUserLoaded()
            guard let userID = sessionService.currentUser?.sub else { return }

            let phrasesToDelete = offsets.map { filteredPhrases[$0] }
            for phrase in phrasesToDelete {
                modelContext.delete(phrase)
                await SavedReelsService.shared.enqueueUnsave(userID: userID, reelID: phrase.reelID)
            }

            do {
                try modelContext.save()
                await syncSavedReels()
                await AppFeedbackPresenter.show(
                    UserFacingMessageMapper.successFeedback(message: LocalizedStrings.savedReelsRemoved),
                    in: $feedbackMessage
                )
            } catch {
                feedbackMessage = UserFacingMessageMapper.errorFeedback(error)
            }
        }
    }

    private func toggleAudio(for phrase: FavoritePhrase) {
        let phraseID = audioPhraseID(for: phrase)
        if audioService.currentlyPlayingPhraseID != phraseID {
            Task {
                await TrackingService.shared.track(
                    event: .audioPlayed,
                    reelID: phrase.trackingReelID,
                    sessionType: .review,
                    metadata: ["surface": .string("saved_phrases")]
                )
            }
        }
        audioService.togglePlayback(for: phraseID, text: phrase.text)
    }

    private func audioPhraseID(for phrase: FavoritePhrase) -> UUID {
        UUID(uuidString: UUIDv5.make(namespace: UUIDv5.namespaceDNS, name: "\(phrase.text)|\(phrase.translation)")) ?? UUID()
    }

    @MainActor
    private func syncSavedReels() async {
        guard let accessToken = sessionService.accessToken else { return }
        await sessionService.ensureCurrentUserLoaded()
        guard let userID = sessionService.currentUser?.sub else { return }

        do {
            if !SavedReelsLocalCache.hasCompletedLegacyMigration(for: userID) {
                let legacyItems = favorites.filter { $0.userID == nil }
                if !legacyItems.isEmpty {
                    let migrated = try await SavedReelsService.shared.migrateLegacyFavorites(
                        accessToken: accessToken,
                        items: legacyItems.map {
                            SavedReelMigrationItem(
                                reelID: $0.reelID.isEmpty ? $0.trackingReelID : $0.reelID,
                                text: $0.text,
                                translation: $0.translation,
                                category: $0.category,
                                difficulty: $0.difficulty
                            )
                        }
                    )
                    for item in legacyItems {
                        modelContext.delete(item)
                    }
                    try modelContext.save()
                    try SavedReelsLocalCache.reconcile(modelContext: modelContext, currentUserID: userID, remoteItems: migrated)
                }
                SavedReelsLocalCache.markLegacyMigrationCompleted(for: userID)
            }

            await SavedReelsService.shared.flushPending(accessToken: accessToken, userID: userID)
            let pendingSaveReelIDs = await SavedReelsService.shared.pendingSaveReelIDs(for: userID)
            let remoteItems = try await SavedReelsService.shared.fetchSavedReels(accessToken: accessToken)
            try SavedReelsLocalCache.reconcile(
                modelContext: modelContext,
                currentUserID: userID,
                remoteItems: remoteItems,
                preservingPendingSaveReelIDs: pendingSaveReelIDs
            )
        } catch {
            Logger.shared.warning("Saved phrases sync failed: \(error.localizedDescription)")
            feedbackMessage = AppFeedbackMessage(
                title: LocalizedStrings.feedbackErrorTitle,
                message: LocalizedStrings.savedReelsSyncError,
                tone: .error
            )
        }
    }
}

// MARK: - Saved Phrase Row Component
struct SavedPhraseRow: View {
    let phrase: FavoritePhrase
    let isPlaying: Bool
    let onPlayAudio: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(phrase.text)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text(phrase.translation)
                        .font(.system(size: 14))
                        .foregroundStyle(LumenColors.textSecondary)
                }
                
                Spacer()
                
                Text(phrase.difficulty)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(Capsule())
            }

            Text(phrase.category)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(LumenColors.textSecondary)

            Button(action: onPlayAudio) {
                HStack(spacing: 8) {
                    Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    Text(isPlaying ? LocalizedStrings.feedStopAudio : LocalizedStrings.feedListen)
                }
                .font(.system(size: 13, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .foregroundStyle(.white)
                .background(Color.white.opacity(0.12))
                .clipShape(Capsule())
            }
        }
        .padding(12)
        .background(LumenColors.navyLight)
        .cornerRadius(12)
    }
}

#Preview {
    SavedPhrasesView()
}

private enum UUIDv5 {
    static let namespaceDNS = "6ba7b810-9dad-11d1-80b4-00c04fd430c8"

    static func make(namespace: String, name: String) -> String {
        let input = "\(namespace)\(name)"
        let hash = Array(input.utf8).reduce(into: [UInt8](repeating: 0, count: 16)) { result, byte in
            let idx = Int(byte) % 16
            result[idx] ^= byte
        }

        var bytes = hash
        bytes[6] = (bytes[6] & 0x0F) | 0x50
        bytes[8] = (bytes[8] & 0x3F) | 0x80

        let hex = bytes.map { String(format: "%02x", $0) }.joined()
        return "\(hex.prefix(8))-\(hex.dropFirst(8).prefix(4))-\(hex.dropFirst(12).prefix(4))-\(hex.dropFirst(16).prefix(4))-\(hex.dropFirst(20).prefix(12))"
    }
}
