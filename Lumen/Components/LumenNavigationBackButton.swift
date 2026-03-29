import SwiftUI

struct LumenNavigationBackButton: ToolbarContent {
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button(action: action) {
                ZStack {
                    Circle()
                        .fill(Color(red: 0.11, green: 0.18, blue: 0.31).opacity(0.94))
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 48, height: 48)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
        }
    }
}
