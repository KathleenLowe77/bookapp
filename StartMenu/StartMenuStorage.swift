import Foundation

enum StartMenuStorage {
    // NEW key name
    private static let linkKeyNew = "StartMenu.Menu"
    // Old key (migration support)
    private static let linkKeyOld = "StartMenu.finalLink"

    // Flag: пользователь навсегда уходит в приложение (без проверок/инициализаций)
    private static let alwaysAppKey = "StartMenu.AlwaysAppMode"

    // MARK: - Link

    static func saveMenu(_ link: String) {
        UserDefaults.standard.set(link, forKey: linkKeyNew)
        // optionally cleanup old key
        UserDefaults.standard.removeObject(forKey: linkKeyOld)
    }

    static func loadMenu() -> String? {
        if let v = UserDefaults.standard.string(forKey: linkKeyNew), !v.isEmpty {
            return v
        }
        // Migrate from old key if present
        if let old = UserDefaults.standard.string(forKey: linkKeyOld), !old.isEmpty {
            UserDefaults.standard.set(old, forKey: linkKeyNew)
            UserDefaults.standard.removeObject(forKey: linkKeyOld)
            return old
        }
        return nil
    }

    static func clearMenu() {
        UserDefaults.standard.removeObject(forKey: linkKeyNew)
        UserDefaults.standard.removeObject(forKey: linkKeyOld)
    }

    // MARK: - Always App Mode

    static func setAlwaysAppMode(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: alwaysAppKey)
    }

    static func isAlwaysAppMode() -> Bool {
        UserDefaults.standard.bool(forKey: alwaysAppKey)
    }
}
