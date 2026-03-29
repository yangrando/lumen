import SwiftUI

struct OnboardingCompletionView: View {
    let onStart: (() -> Void)?
    let autoAdvance: Bool

    @State private var didStart = false
    @State private var pulse = false
    @State private var activeStep = 0

    private let steps = [
        "Analisando seus interesses",
        "Montando o seu feed",
        "Gerando os primeiros reels"
    ]

    init(autoAdvance: Bool = true, onStart: (() -> Void)? = nil) {
        self.autoAdvance = autoAdvance
        self.onStart = onStart
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.07, blue: 0.14),
                    Color(red: 0.04, green: 0.09, blue: 0.17),
                    Color(red: 0.02, green: 0.06, blue: 0.13)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(LinearGradient.primaryGradient.opacity(0.16))
                        .frame(width: 180, height: 180)
                        .blur(radius: 8)
                        .scaleEffect(pulse ? 1.08 : 0.92)

                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        .frame(width: 132, height: 132)

                    Image("LumenLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                }

                VStack(spacing: 12) {
                    Text("Criando sua experiência")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Estamos preparando o seu feed inicial com frases no nível certo, temas do seu interesse e reels personalizados.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(LumenColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                }

                VStack(spacing: 12) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        stepRow(title: step, isActive: index <= activeStep)
                    }
                }
                .padding(20)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .task {
            guard !didStart else { return }
            didStart = true
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
            for index in steps.indices {
                activeStep = index
                try? await Task.sleep(nanoseconds: 900_000_000)
            }
            if autoAdvance {
                onStart?()
            }
        }
    }

    private func stepRow(title: String, isActive: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(isActive ? AnyShapeStyle(LinearGradient.primaryGradient) : AnyShapeStyle(Color.white.opacity(0.08)))
                    .frame(width: 32, height: 32)

                Image(systemName: isActive ? "checkmark" : "circle.fill")
                    .font(.system(size: isActive ? 13 : 8, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isActive ? .white : LumenColors.textSecondary)

            Spacer()
        }
    }
}
