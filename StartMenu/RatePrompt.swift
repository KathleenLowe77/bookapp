// RatePrompt.swift (фрагмент)
import StoreKit
import UIKit

enum RatePrompt {
    private static var tapCount = 0
    private static let threshold = 15

    static func registerTap(source: String) {
        tapCount += 1
        print("[Rate] tap #\(tapCount) source=\(source)")

        // Запрашиваем отзыв ТОЛЬКО из веба
        guard source == "web", tapCount >= threshold else { return }

        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
        tapCount = 0
    }
}
