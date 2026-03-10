import SwiftUI

struct UserPreferencesView: View {
    let accessToken: String

    @Environment(\.dismiss) private var dismiss

    @State private var selectedLevel: EnglishLevel = .intermediate
    @State private var selectedNativeLanguage = "Portuguese (Brazil)"
    @State private var selectedInterests: Set<UserInterest> = []
    @State private var selectedObjectives: Set<LearningObjective> = []
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                LumenColors.navyDark
                    .ignoresSafeArea()

                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            Text(LocalizedStrings.preferencesEnglishLevel)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)

                            Picker("Level", selection: $selectedLevel) {
                                ForEach(EnglishLevel.allCases) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            .padding(.horizontal, 12)
                            .frame(height: 42)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            Text(LocalizedStrings.preferencesNativeLanguage)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)

                            Picker("Native language", selection: $selectedNativeLanguage) {
                                ForEach(nativeLanguages) { language in
                                    Text(language.localizedLabel).tag(language.value)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(.white)
                            .padding(.horizontal, 12)
                            .frame(height: 42)
                            .background(Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                            Text(LocalizedStrings.preferencesInterests)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)

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

                            Text(LocalizedStrings.preferencesObjectives)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)

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
                            .padding(.top, 8)
                        }
                        .padding(18)
                    }
                }
            }
            .navigationTitle(LocalizedStrings.preferencesEditProfileTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(LocalizedStrings.commonClose) { dismiss() }
                        .foregroundStyle(.white)
                }
            }
            .task {
                await load()
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let preferences = try await AuthService.shared.fetchCurrentUserPreferences(accessToken: accessToken)
            selectedLevel = EnglishLevel(rawValue: preferences.level) ?? .intermediate
            selectedNativeLanguage = preferences.nativeLanguage
            selectedInterests = Set(preferences.interests.compactMap(UserInterest.init(rawValue:)))
            selectedObjectives = Set(preferences.objectives.compactMap(LearningObjective.init(rawValue:)))
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
        VStack(alignment: .leading, spacing: 8) {
            ForEach(chunked(items, size: 2), id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { item in
                        Button {
                            onToggle(item)
                        } label: {
                            Text(item)
                                .font(.system(size: 12, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .foregroundStyle(selectedItems.contains(item) ? .white : LumenColors.textSecondary)
                                .background(
                                    selectedItems.contains(item)
                                    ? AnyShapeStyle(LinearGradient.primaryGradient)
                                    : AnyShapeStyle(Color.white.opacity(0.08))
                                )
                                .clipShape(Capsule())
                        }
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

#Preview {
    UserPreferencesView(accessToken: "token")
}
