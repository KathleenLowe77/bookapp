import Foundation
import UserNotifications
#if canImport(OneSignalFramework)
import OneSignalFramework
#endif

final class OneSignalManager {
    static let shared = OneSignalManager()
    private init() {}

    private(set) var oneSignalUserID: String? // os_id

    /// Запрашивает пуш-разрешение, инициализирует OneSignal (если app id задан),
    /// ждёт появления pushSubscription.id до 5 секунд. Ранний выход при успехе.
    @discardableResult
    func requestPushThenInitIfNeeded() async -> String? {
        // 1) Разрешение на пуши
        let granted = await requestPushPermission()
        guard granted else {

            return nil
        }

        // 2) App ID должен быть указан
        guard !StartupConfig.oneSignalAppID.isEmpty else {

            return nil
        }

        #if canImport(OneSignalFramework)
        // 3) Инициализация SDK
        OneSignal.initialize(StartupConfig.oneSignalAppID, withLaunchOptions: nil)

        // 4) Мгновенная проверка: вдруг id уже есть
        if let id = OneSignal.User.pushSubscription.id, !id.isEmpty {
            self.oneSignalUserID = id

            OneSignal.User.addTag(key: "player_status", value: "target")
            return id
        }

        // 5) Поллинг до 5 сек: 50 × 100мс
        for attempt in 1...50 {
            try? await Task.sleep(nanoseconds: 100_000_000)
            if let id = OneSignal.User.pushSubscription.id, !id.isEmpty {
                self.oneSignalUserID = id

                OneSignal.User.addTag(key: "player_status", value: "target")
                return id
            }
        }


        return nil
        #else

        return nil
        #endif
    }

    private func requestPushPermission() async -> Bool {
        await withCheckedContinuation { cont in
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { ok, _ in
                DispatchQueue.main.async { cont.resume(returning: ok) }
            }
        }
    }
}
