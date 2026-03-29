import SwiftUI

struct InterestsView: View {
    @State private var selectedInterests: Set<UserInterest> = []

    let onBack: () -> Void
    let onContinue: ([UserInterest]) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            onboardingBackground

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header

                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(orderedInterests) { interest in
                            InterestCard(
                                interest: interest,
                                isSelected: selectedInterests.contains(interest),
                                action: {
                                    if selectedInterests.contains(interest) {
                                        selectedInterests.remove(interest)
                                    } else {
                                        selectedInterests.insert(interest)
                                    }
                                }
                            )
                        }
                    }

                    infoCard
                        .padding(.top, 8)

                    Color.clear
                        .frame(height: 130)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 20)
            }

            bottomAction
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var onboardingBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.08, blue: 0.16),
                    Color(red: 0.05, green: 0.10, blue: 0.20),
                    Color(red: 0.04, green: 0.08, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [
                    LumenColors.gradientEnd.opacity(0.18),
                    .clear
                ],
                center: .top,
                startRadius: 40,
                endRadius: 340
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 42, height: 42)
                    .background(Color.white.opacity(0.06))
                    .clipShape(Circle())
            }

            Text(LocalizedStrings.interestsTitle)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)

            Text(LocalizedStrings.interestsDescription)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(LumenColors.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var infoCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(LumenColors.gradientStart)
                .frame(width: 24)

            Text("A IA do Lumen usara esses topicos para gerar frases em ingles contextualizadas com o que voce gosta.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white.opacity(0.88))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        }
    }

    private var bottomAction: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            VStack(spacing: 0) {
                Button(action: {
                    let selectedArray = Array(selectedInterests).sorted { $0.rawValue < $1.rawValue }
                    onContinue(selectedArray)
                }) {
                    Text(LocalizedStrings.interestsContinueButton)
                        .font(.system(size: 17, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .frame(height: 58)
                    .foregroundStyle(.white)
                    .background(
                        selectedInterests.isEmpty
                        ? AnyShapeStyle(Color.white.opacity(0.10))
                        : AnyShapeStyle(LinearGradient.primaryGradient)
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(selectedInterests.isEmpty)
                .opacity(selectedInterests.isEmpty ? 0.55 : 1.0)
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)
            .padding(.bottom, 15)
            .background(
                LinearGradient(
                    colors: [
                        LumenColors.navyDark.opacity(0.0),
                        LumenColors.navyDark.opacity(0.96),
                        LumenColors.navyDark
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea(edges: .bottom)
            )
        }
    }

    private var orderedInterests: [UserInterest] {
        let preferredOrder: [UserInterest] = [
            .entertainment,
            .music,
            .travel,
            .food,
            .technology,
            .science,
            .sports,
            .business,
            .health,
            .art,
            .fashion,
            .gaming
        ]

        return preferredOrder
    }
}

#Preview {
    InterestsView(onBack: {}, onContinue: { _ in })
}
