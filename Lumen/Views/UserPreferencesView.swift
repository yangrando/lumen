import SwiftUI

struct UserPreferencesView: View {
    let accessToken: String

    @Environment(\.dismiss) private var dismiss

    @State private var currentUser: AuthUser?
    @State private var selectedLevel: EnglishLevel = .b1
    @State private var selectedNativeLanguage = "Portuguese (Brazil)"
    @State private var selectedInterests: Set<UserInterest> = []
    @State private var selectedObjectives: Set<LearningObjective> = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            LumenColors.navyDark
                .ignoresSafeArea()

            if isLoading {
                ProgressView()
                    .tint(.white)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        profileHero
                        personalInformationCard
                        learningContextCard
                        accountActions
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

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
                        .fill(Color(red: 0.10, green: 0.18, blue: 0.30))
                        .frame(width: 40, height: 40)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 16, weight: .semibold))
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
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)

                Text(memberSinceText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(LumenColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var personalInformationCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("Personal Information")

            settingsCard {
                settingsField(
                    label: "FULL NAME",
                    value: displayName
                )

                DividerRow()

                settingsField(
                    label: "EMAIL ADDRESS",
                    value: currentUser?.email ?? "No email available"
                )

                DividerRow()

                VStack(alignment: .leading, spacing: 12) {
                    Text("NATIVE LANGUAGE")
                        .font(.system(size: 12, weight: .bold))
                        .tracking(1.1)
                        .foregroundStyle(Color(red: 0.54, green: 0.60, blue: 0.71))

                    Picker("Native language", selection: $selectedNativeLanguage) {
                        ForEach(nativeLanguages) { language in
                            Text(language.localizedLabel).tag(language.value)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.white)
                }
            }
        }
    }

    private var learningContextCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionTitle("Learning Context")

            settingsCard(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    chipTitle(LocalizedStrings.preferencesInterests.uppercased())
                    FlexibleChips(
                        items: UserInterest.allCases.map(\.rawValue),
                        selectedItems: Set(selectedInterests.map(\.rawValue)),
                        onToggle: { raw in
                            guard let item = UserInterest(rawValue: raw) else { return }
                            if selectedInterests.contains(item) {
                                selectedInterests.remove(item)
                            } else {
                                selectedInterests.insert(item)
                            }
                        }
                    )
                }

                VStack(alignment: .leading, spacing: 12) {
                    chipTitle(LocalizedStrings.preferencesObjectives.uppercased())
                    FlexibleChips(
                        items: LearningObjective.allCases.map(\.rawValue),
                        selectedItems: Set(selectedObjectives.map(\.rawValue)),
                        onToggle: { raw in
                            guard let item = LearningObjective(rawValue: raw) else { return }
                            if selectedObjectives.contains(item) {
                                selectedObjectives.remove(item)
                            } else {
                                selectedObjectives.insert(item)
                            }
                        }
                    )
                }

                VStack(alignment: .leading, spacing: 18) {
                    chipTitle(LocalizedStrings.preferencesEnglishLevel.uppercased())
                    levelSelector
                    levelDescription
                }
            }
        }
    }

    private var accountActions: some View {
        VStack(spacing: 18) {
            if let errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.red.opacity(0.95))
            }

            GradientButton(
                title: isSaving ? LocalizedStrings.preferencesSaving : LocalizedStrings.preferencesSaveChanges,
                icon: "square.and.arrow.down.fill",
                action: {
                    Task { await save() }
                }
            )
            .disabled(isSaving)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(.white)
    }

    private func settingsCard(spacing: CGFloat = 18, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: spacing) {
            content()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.05), lineWidth: 1)
        }
    }

    private func settingsField(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label)
                .font(.system(size: 12, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(Color(red: 0.54, green: 0.60, blue: 0.71))

            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private func chipTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .bold))
            .tracking(1.1)
            .foregroundStyle(Color(red: 0.54, green: 0.60, blue: 0.71))
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
                            .font(.system(size: 15, weight: .semibold))
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
            .font(.system(size: 13, weight: .medium))
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
            selectedObjectives = Set(preferences.objectives.compactMap(LearningObjective.init(rawValue:)))
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
            objectives: selectedObjectives.map(\.rawValue).sorted()
        )

        do {
            _ = try await AuthService.shared.updateCurrentUserPreferences(accessToken: accessToken, preferences: payload)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var displayName: String {
        let trimmed = currentUser?.name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Lumen Learner" : trimmed
    }

    private var memberSinceText: String {
        "Lumen learner"
    }

    private var levelHelperText: String {
        switch selectedLevel {
        case .a1:
            return "Short, highly familiar sentences with daily vocabulary and strong contextual support."
        case .a2:
            return "Simple connected phrases for common situations, routines, and basic opinions."
        case .b1:
            return "Independent reading on familiar themes with more detail and clearer narratives."
        case .b2:
            return "More natural connected texts with richer ideas, contrast, and less frequent vocabulary."
        case .c1:
            return "Advanced texts with nuanced ideas, denser vocabulary, and more flexible grammar."
        case .c2:
            return "Near-native complexity with subtle tone, idioms, and culturally rich references."
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

private struct FlexibleChips: View {
    let items: [String]
    let selectedItems: Set<String>
    let onToggle: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(chunked(items, size: 2), id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { item in
                        Button {
                            onToggle(item)
                        } label: {
                            Text(item)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(selectedItems.contains(item) ? .white : LumenColors.textSecondary)
                                .background(
                                    selectedItems.contains(item)
                                    ? AnyShapeStyle(LinearGradient.primaryGradient)
                                    : AnyShapeStyle(Color.white.opacity(0.08))
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }

                    if row.count == 1 {
                        Color.clear.frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func chunked(_ source: [String], size: Int) -> [[String]] {
        guard size > 0 else { return [] }
        var chunks: [[String]] = []
        var index = 0
        while index < source.count {
            let end = min(index + size, source.count)
            chunks.append(Array(source[index..<end]))
            index += size
        }
        return chunks
    }
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
