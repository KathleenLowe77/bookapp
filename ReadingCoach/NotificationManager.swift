import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let noonId = "daily_noon_reminder"

    private let messagesEN = [
        "Time to read a few pages 📖",
        "Tiny steps, big progress — open your book!",
        "12 minutes for 12 o’clock? Let’s read.",
        "Turn one page. Then another.",
        "Your future self will thank you. Read today."
    ]

    /// Вызывайте при изменении тумблера. Если `enabled == true`, запрашивает разрешение и ставит расписание.
    /// В completion вернётся фактический статус (true — разрешено и запланировано; false — отключено).
    func setEnabledWithPermission(_ enabled: Bool, completion: @escaping (Bool) -> Void) {
        if !enabled {
            cancelNoon()
            completion(false)
            return
        }
        // enabled == true -> просим разрешение, если надо
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                self.scheduleNoonRepeating()
                DispatchQueue.main.async { completion(true) }
            case .denied:
                // Уже запрещено в системных настройках
                DispatchQueue.main.async { completion(false) }
            case .notDetermined:
                self.requestAuth { granted in
                    if granted {
                        self.scheduleNoonRepeating()
                    }
                    DispatchQueue.main.async { completion(granted) }
                }
            @unknown default:
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    // Старый хелпер можно оставить для обратной совместимости (не обязателен)
    func bootstrapNotifications(enabled: Bool) {
        setEnabledWithPermission(enabled) { _ in }
    }

    func rescheduleNoon() {
        cancelNoon()
        scheduleNoonRepeating()
    }

    private func requestAuth(_ completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { ok, _ in
            completion(ok)
        }
    }

    private func scheduleNoonRepeating() {
        let content = UNMutableNotificationContent()
        content.title = "Reading time"
        content.body = messagesEN.randomElement() ?? "Time to read a few pages 📖"
        content.sound = .default

        var date = DateComponents()
        date.hour = 12
        date.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let req = UNNotificationRequest(identifier: noonId, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(req) { err in
            if let err = err {
                print("Notify schedule error:", err)
            }
        }
    }

    private func cancelNoon() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [noonId])
    }
}
