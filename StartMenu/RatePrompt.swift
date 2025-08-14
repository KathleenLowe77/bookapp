import Foundation
import StoreKit
import UIKit

enum RatePrompt {
    private static let tapKey = "StartMenu.Rate.TapCount"
    /// Порог. Для теста ставь 10. В проде — 100.
    private static let threshold = 10

    /// Регистрируем тап. `source` — откуда пришёл (native/web) для логов.
    static func registerTap(source: String = "native") {
        let d = UserDefaults.standard
        var count = d.integer(forKey: tapKey)
        count += 1
        d.set(count, forKey: tapKey)


        guard count >= threshold else { return }
        // сбрасываем и просим показать системный промпт
        d.set(0, forKey: tapKey)
        requestReview()
    }

    private static func requestReview() {
        DispatchQueue.main.async {
            guard let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }) else {
                    return
                }
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    /// (Опционально) Форс-открыть страницу отзывов в App Store — полезно в DEBUG,
    /// если системное окно не показывается по внутренним правилам Apple.
    static func debugOpenWriteReview() {
        let appId = StartupConfig.appsFlyerAppID  // это и есть App Store numeric ID
        if let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appId)?action=write-review") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
        }
    }

    /// Для тестов: принудительный сброс счётчика.
    static func resetCounter() { UserDefaults.standard.set(0, forKey: tapKey) }
}
