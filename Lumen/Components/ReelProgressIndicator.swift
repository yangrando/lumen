import SwiftUI

struct ReelProgressIndicator: View {
    let state: ReelLearningState

    private var progress: CGFloat {
        CGFloat(state.progressCount) / CGFloat(ReelLearningState.totalSteps)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text("Progress:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.72))
                Text("\(state.progressCount) / \(ReelLearningState.totalSteps)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.14))
                    Capsule()
                        .fill(LinearGradient.primaryGradient)
                        .frame(width: max(18, geometry.size.width * progress))
                        .animation(.easeInOut(duration: 0.25), value: progress)
                }
            }
            .frame(height: 7)

            if state.isCompleted {
                Text("✔ Reel completed")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(red: 0.50, green: 0.93, blue: 0.72))
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.09, green: 0.16, blue: 0.27).opacity(0.78))
        )
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        }
    }
}
