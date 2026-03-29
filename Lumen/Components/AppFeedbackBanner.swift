import SwiftUI

struct AppFeedbackMessage: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let message: String
    let tone: ToastView.Tone
}

private struct AppFeedbackBannerModifier: ViewModifier {
    @Binding var message: AppFeedbackMessage?

    func body(content: Content) -> some View {
        ZStack {
            content

            if let message {
                VStack {
                    ToastView(
                        title: message.title,
                        message: message.message,
                        tone: message.tone
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 18)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}

extension View {
    func appFeedbackBanner(_ message: Binding<AppFeedbackMessage?>) -> some View {
        modifier(AppFeedbackBannerModifier(message: message))
    }
}

@MainActor
enum AppFeedbackPresenter {
    static func show(
        _ message: AppFeedbackMessage,
        in binding: Binding<AppFeedbackMessage?>,
        durationNanoseconds: UInt64 = 2_000_000_000
    ) async {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
            binding.wrappedValue = message
        }

        try? await Task.sleep(nanoseconds: durationNanoseconds)

        withAnimation(.easeInOut(duration: 0.2)) {
            if binding.wrappedValue?.id == message.id {
                binding.wrappedValue = nil
            }
        }
    }
}
