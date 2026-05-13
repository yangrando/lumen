import SwiftUI

struct UserPreferencesView: View {
    let accessToken: String

    @Environment(\.dismiss) private var dismiss

    @State private var currentUser: AuthUser?
    @State private var selectedLevel: EnglishLevel = .b1
    @State private var selectedNativeLanguage = "Portuguese (Brazil)"
    @State private var selectedInterests: Set<UserInterest> = []
    @State private var selectedSubtopics: Set<LearningSubtopic> = []
    @State private var selectedObjectives: Set<LearningObjective> = []
    @State private var selectedContentStylePreference: ContentStylePreference = .mixed
    @State private var selectedProfession: ProfessionOption?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            LumenColors.ink900
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(LumenColors.accent)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        // Settings title + version (design-spec)
                        HStack {
                            Text(LocalizedStrings.preferencesTitle)
                                .font(LumenFont.grotesk(22, weight: .semibold))
                                .foregroundStyle(LumenColors.ink50)
                            Spacer()
                            Text("v 1.0")
                                .font(LumenFont.mono(10, weight: .medium))
                                .tracking(1.4)
                                .foregroundStyle(LumenColors.ink400)
                        }

                        // Account section
                        settingsGroup(header: "ACCOUNT") {
                            settingsListRow(
                                label: LocalizedStrings.preferencesFullName,
                                value: displayName
                            )
                            Divider().background(LumenColors.ink700)
                            settingsListRow(
                                label: LocalizedStrings.preferencesEmailAddress,
                                value: currentUser?.email ?? LocalizedStrings.preferencesNoEmailAvailable,
                                isAccent: false
                            )
                        }

                        // Practice section
                        settingsGroup(header: "PRACTICE") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizedStrings.preferencesNativeLanguage.uppercased())
                                    .font(LumenFont.mono(10, weight: .medium))
                                    .tracking(1.4)
                                    .foregroundStyle(LumenColors.ink400)

                                Picker(LocalizedStrings.preferencesNativeLanguage, selection: $selectedNativeLanguage) {
                                    ForEach(nativeLanguages) { language in
                                        Text(language.localizedLabel).tag(language.value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .tint(LumenColors.accent)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 14)

                        }

                        // Learning context — collapsible sections
                        learningContextSection

                        // Save button
                        if let errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(LumenFont.grotesk(13, weight: .medium))
                                .foregroundStyle(LumenColors.bad)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity)
                        }

                        LumenButton(
                            kind: .primary, size: .lg,
                            isDisabled: isSaving,
                            isFullWidth: true,
                            label: isSaving ? LocalizedStrings.preferencesSaving : LocalizedStrings.preferencesSaveChanges
                        ) {
                            Task { await save() }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 36)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    // MARK: – Design-spec helpers

    private func settingsGroup(header: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header)
                .font(LumenFont.mono(9, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(LumenColors.ink400)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .background(LumenColors.ink800)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LumenColors.ink700, lineWidth: 1)
            }
        }
    }

    private func settingsListRow(label: String, value: String, isAccent: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(LumenFont.grotesk(14, weight: .medium))
                .foregroundStyle(LumenColors.ink50)
            Spacer()
            Text(value)
                .font(LumenFont.grotesk(13))
                .foregroundStyle(isAccent ? LumenColors.accent : LumenColors.ink400)
                .lineLimit(1)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(LumenColors.ink500)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
    }

    private var learningContextSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("LEARNING CONTEXT")
                .font(LumenFont.mono(9, weight: .medium))
                .tracking(1.4)
                .foregroundStyle(LumenColors.ink400)
                .padding(.leading, 4)

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    chipTitle(LocalizedStrings.preferencesInterests.uppercased())
                    ChipSelectionGrid(
                        items: UserInterest.allCases,
                        selectedItems: selectedInterests,
                        title: \.displayTitle,
                        onToggle: { item in
                            if selectedInterests.contains(item) {
                                selectedInterests.remove(item)
                            } else {
                                selectedInterests.insert(item)
                            }
                            selectedSubtopics = Set(selectedSubtopics.filter { !$0.topics.isDisjoint(with: selectedInterests) })
                        }
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    chipTitle(LocalizedStrings.preferencesSubtopics.uppercased())
                    ChipSelectionGrid(
                        items: availableSubtopics,
                        selectedItems: selectedSubtopics,
                        title: \.displayTitle,
                        onToggle: { item in
                            if selectedSubtopics.contains(item) {
                                selectedSubtopics.remove(item)
                            } else {
                                selectedSubtopics.insert(item)
                            }
                        }
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    chipTitle(LocalizedStrings.preferencesObjectives.uppercased())
                    ChipSelectionGrid(
                        items: LearningObjective.onboardingCases,
                        selectedItems: selectedObjectives,
                        title: \.displayTitle,
                        onToggle: { item in
                            if selectedObjectives.contains(item) {
                                selectedObjectives.remove(item)
                            } else {
                                selectedObjectives.insert(item)
                            }
                        }
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    chipTitle(LocalizedStrings.preferencesContentStyle.uppercased())
                    ChipSelectionGrid(
                        items: ContentStylePreference.allCases,
                        selectedItems: Set([selectedContentStylePreference]),
                        title: \.displayTitle,
                        onToggle: { selectedContentStylePreference = $0 }
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    chipTitle(LocalizedStrings.preferencesProfession.uppercased())
                    ChipSelectionGrid(
                        items: ProfessionOption.allCases,
                        selectedItems: selectedProfession.map { Set([$0]) } ?? [],
                        title: \.displayTitle,
                        onToggle: { selectedProfession = selectedProfession == $0 ? nil : $0 }
                    )
                }

                VStack(alignment: .leading, spacing: 18) {
                    chipTitle(LocalizedStrings.preferencesEnglishLevel.uppercased())
                    levelSelector
                    levelDescription
                }
            }
            .padding(16)
            .background(LumenColors.ink800)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LumenColors.ink700, lineWidth: 1)
            }
        }
    }

    // MARK: – Legacy (kept for internal use)

    private var profileHero: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                LumenColors.gradientStart.opacity(0.42),
                                LumenColors.gradientEnd.opacity(0.22),
                                .clear
                            ],
                            center: .center,
                            startRadius: 18,
                            endRadius: 96
                        )
                    )
                    .frame(width: 176, height: 176)

                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(LumenColors.navyLight)
                        .frame(width: 128, height: 128)
                        .overlay {
                            Circle()
                                .stroke(Color.black.opacity(0.32), lineWidth: 8)
                        }
                        .overlay {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 92, height: 92)
                                .foregroundStyle(.white.opacity(0.94), LumenColors.textSecondary.opacity(0.65))
                        }

                    Circle()
                        .fill(LumenColors.ink700)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(LumenFont.grotesk(16, weight: .semibold))
                                .foregroundStyle(LumenColors.gradientStart)
                        }
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        }
                        .offset(x: 6, y: 4)
                }
            }

            VStack(spacing: 5) {
                Text(displayName)
                    .font(LumenFont.grotesk(24, weight: .bold))
                    .foregroundStyle(.white)

                Text(memberSinceText)
                    .font(LumenFont.grotesk(14, weight: .medium))
                    .foregroundStyle(LumenColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func settingsCard(spacing: CGFloat = 18, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(LumenColors.ink800)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(LumenColors.ink700, lineWidth: 1)
        }
    }

    private func settingsField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(LumenFont.mono(12, weight: .medium))
                .tracking(1.1)
                .foregroundStyle(LumenColors.ink400)

            Text(value)
                .font(LumenFont.grotesk(16, weight: .medium))
                .foregroundStyle(LumenColors.ink50)
        }
    }

    private func chipTitle(_ text: String) -> some View {
        Text(text)
            .font(LumenFont.mono(12, weight: .medium))
            .tracking(1.1)
            .foregroundStyle(LumenColors.ink400)
    }

    private var levelSelector: some View {
        VStack(spacing: 16) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10)
                ],
                spacing: 10
            ) {
                ForEach(EnglishLevel.allCases) { level in
                    Button {
                        selectedLevel = level
                    } label: {
                        Text(level.rawValue)
                            .font(LumenFont.grotesk(15, weight: .semibold))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .foregroundStyle(selectedLevel == level ? .white : LumenColors.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: 52)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        selectedLevel == level
                                        ? AnyShapeStyle(LinearGradient.primaryGradient)
                                        : AnyShapeStyle(Color.white.opacity(0.06))
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var levelDescription: some View {
        Text(levelHelperText)
            .font(LumenFont.grotesk(13, weight: .medium))
            .foregroundStyle(LumenColors.textSecondary)
            .italic()
            .frame(maxWidth: .infinity, alignment: .center)
            .multilineTextAlignment(.center)
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let userTask = AuthService.shared.fetchCurrentUser(accessToken: accessToken)
            async let preferencesTask = AuthService.shared.fetchCurrentUserPreferences(accessToken: accessToken)

            let (user, preferences) = try await (userTask, preferencesTask)
            currentUser = user
            selectedLevel = EnglishLevel(label: preferences.level)
            selectedNativeLanguage = preferences.nativeLanguage
            selectedInterests = Set(preferences.interests.compactMap(UserInterest.init(rawValue:)))
            selectedSubtopics = Set(
                preferences.subtopics.compactMap(LearningSubtopic.from(id:))
                    .filter { !$0.topics.isDisjoint(with: selectedInterests) }
            )
            selectedObjectives = Set(preferences.objectives.compactMap(LearningObjective.init(rawValue:)))
            selectedContentStylePreference = ContentStylePreference(rawValue: preferences.contentStylePreference) ?? .mixed
            selectedProfession = preferences.profession.flatMap(ProfessionOption.init(rawValue:))
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let payload = UserPreferences(
            level: selectedLevel.rawValue,
            nativeLanguage: selectedNativeLanguage,
            interests: selectedInterests.map(\.rawValue).sorted(),
            subtopics: selectedSubtopics.map(\.id).sorted(),
            objectives: selectedObjectives.map(\.rawValue).sorted(),
            contentStylePreference: selectedContentStylePreference.rawValue,
            profession: selectedProfession?.rawValue
        )

        do {
            let previousLanguage = NativeLanguageLocalization.preferredNativeLanguage()
            _ = try await AuthService.shared.updateCurrentUserPreferences(accessToken: accessToken, preferences: payload)
            dismiss()
            if payload.nativeLanguage != previousLanguage {
                NotificationCenter.default.post(name: NativeLanguageLocalization.didChangeNotification, object: nil)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var displayName: String {
        let trimmed = currentUser?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? LocalizedStrings.profileDefaultName : trimmed
    }

    private var availableSubtopics: [LearningSubtopic] {
        LearningSubtopic.options(for: selectedInterests)
    }

    private var memberSinceText: String {
        LocalizedStrings.preferencesMemberSince
    }

    private var levelHelperText: String {
        switch selectedLevel {
        case .a1:
            return LocalizedStrings.preferencesLevelHelperA1
        case .a2:
            return LocalizedStrings.preferencesLevelHelperA2
        case .b1:
            return LocalizedStrings.preferencesLevelHelperB1
        case .b2:
            return LocalizedStrings.preferencesLevelHelperB2
        case .c1:
            return LocalizedStrings.preferencesLevelHelperC1
        case .c2:
            return LocalizedStrings.preferencesLevelHelperC2
        }
    }

    private let nativeLanguages: [NativeLanguageOption] = [
        .init(value: "Portuguese (Brazil)", localizedLabel: LocalizedStrings.nativeLanguageOptionPortugueseBrazil),
        .init(value: "Spanish", localizedLabel: LocalizedStrings.nativeLanguageOptionSpanish),
        .init(value: "English", localizedLabel: LocalizedStrings.nativeLanguageOptionEnglish),
        .init(value: "French", localizedLabel: LocalizedStrings.nativeLanguageOptionFrench),
        .init(value: "German", localizedLabel: LocalizedStrings.nativeLanguageOptionGerman),
        .init(value: "Italian", localizedLabel: LocalizedStrings.nativeLanguageOptionItalian),
        .init(value: "Russian", localizedLabel: LocalizedStrings.nativeLanguageOptionRussian),
        .init(value: "Japanese", localizedLabel: LocalizedStrings.nativeLanguageOptionJapanese),
        .init(value: "Korean", localizedLabel: LocalizedStrings.nativeLanguageOptionKorean),
        .init(value: "Chinese (Simplified)", localizedLabel: LocalizedStrings.nativeLanguageOptionChineseSimplified)
    ]
}

private struct NativeLanguageOption: Identifiable {
    let value: String
    let localizedLabel: String
    var id: String { value }
}

private struct DividerRow: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
    }
}

#Preview {
    NavigationStack {
        UserPreferencesView(accessToken: "token")
    }
}
