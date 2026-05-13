import SwiftUI

struct LumenNavigationBackButton: ToolbarContent {
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(LumenColors.ink800.opacity(0.94))
                    Image(systemName: "chevron.left")
                        .font(LumenFont.grotesk(20, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 48, height: 48)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}
