import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case en = "en"
    case fr = "fr"
    case es = "es"
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .en: return "English"
        case .fr: return "Français"
        case .es: return "Español"
        }
    }
}
