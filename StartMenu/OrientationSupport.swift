import UIKit

// Глобальный «переключатель» ориентации
enum OrientationLock {
    // По умолчанию держим портрет
    static var current: UIInterfaceOrientationMask = .portrait
}

// Делегат приложения, чтобы система знала текущую маску
final class StartMenuAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        OrientationLock.current
    }
}
