import SwiftUI

struct InterestCard: View {
    let interest: UserInterest
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    Spacer()

                    ZStack {
                        Circle()
                            .stroke(
                                isSelected
                                ? Color.white.opacity(0.18)
                                : Color(red: 0.30, green: 0.36, blue: 0.47),
                                lineWidth: 3
                            )
                            .frame(width: 25, height: 25)

                        if isSelected {
                            Circle()
                                .fill(Color.white.opacity(0.18))
                                .frame(width: 25, height: 25)

                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }

                Spacer(minLength: 8)

                HStack {
                    Spacer()
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(isSelected ? 0.18 : 0.06))
                            .frame(width: 72, height: 72)

                        Image(systemName: interest.icon)
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white.opacity(isSelected ? 0.96 : 0.82))
                    }
                    Spacer()
                }

                Spacer()

                VStack(alignment: .leading, spacing: 6) {
                    Text(interest.displayTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white.opacity(isSelected ? 1 : 0.92))
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)

                    Text(interest.displaySubtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(isSelected ? Color.white.opacity(0.72) : LumenColors.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 228, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(backgroundShape)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(
                        isSelected ? Color.white.opacity(0.18) : Color.white.opacity(0.08),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(
                color: isSelected ? LumenColors.gradientEnd.opacity(0.18) : Color.black.opacity(0.12),
                radius: 18,
                x: 0,
                y: 10
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSelected)
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var backgroundShape: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        LumenColors.gradientStart.opacity(0.96),
                        Color(red: 0.34, green: 0.52, blue: 0.95),
                        LumenColors.gradientEnd.opacity(0.95)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }

        return AnyShapeStyle(Color(red: 0.14, green: 0.18, blue: 0.27))
    }
}

private extension UserInterest {
    var displayTitle: String {
        switch self {
        case .entertainment:
            return "Filmes & Series"
        case .music:
            return "Musica"
        case .travel:
            return "Viagens"
        case .food:
            return "Culinaria"
        case .technology:
            return "Tecnologia & Ciencia"
        case .science:
            return "Pesquisa"
        case .sports:
            return "Esportes"
        case .business:
            return "Negocios"
        case .health:
            return "Saude"
        case .art:
            return "Arte"
        case .fashion:
            return "Moda"
        case .gaming:
            return "Games"
        }
    }

    var displaySubtitle: String {
        switch self {
        case .entertainment:
            return "Cultura pop"
        case .music:
            return "Ritmo e artistas"
        case .travel:
            return "Destinos e culturas"
        case .food:
            return "Gastronomia"
        case .technology:
            return "Inovacao"
        case .science:
            return "Descobertas"
        case .sports:
            return "Competicao"
        case .business:
            return "Carreira e mercado"
        case .health:
            return "Bem-estar"
        case .art:
            return "Criatividade"
        case .fashion:
            return "Estilo"
        case .gaming:
            return "Entretenimento digital"
        }
    }
}
