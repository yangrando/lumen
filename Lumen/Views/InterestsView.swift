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
            LumenColors.navyDark
                .ignoresSafeArea()

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

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
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

            VStack(spacing: 16) {
                Button(action: {
                    let selectedArray = Array(selectedInterests).sorted { $0.rawValue < $1.rawValue }
                    onContinue(selectedArray)
                }) {
                    HStack(spacing: 10) {
                        Text(LocalizedStrings.interestsContinueButton)
                            .font(.system(size: 17, weight: .bold))

                        Image(systemName: "arrow.right")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .foregroundStyle(.white)
                    .background(LinearGradient.primaryGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: LumenColors.gradientEnd.opacity(0.28), radius: 20, x: 0, y: 10)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 26)
            .background(LumenColors.navyDark)
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
