import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark, sepia
    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        case .sepia: return "Sepia"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        case .sepia: return nil
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .sepia:
            return Color(red: 0.96, green: 0.93, blue: 0.85)
        default:
            return Color(.systemBackground)
        }
    }
}
