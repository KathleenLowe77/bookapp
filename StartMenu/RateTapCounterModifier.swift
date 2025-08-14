import SwiftUI

struct RateTapCounter: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .simultaneousGesture(
                TapGesture().onEnded {
                    RatePrompt.registerTap(source: "native")
                }
            )
    }
}

extension View {
    /// Счётчик тапов для показа нативного рейтинга
    func enableRateAfterTaps() -> some View {
        self.modifier(RateTapCounter())
    }
}
