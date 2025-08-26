import SwiftUI
import SwiftData

@main
struct ReadingCoachApp: App {
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.en.rawValue
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootTabsView()
                .environment(\.locale, Locale(identifier: appLanguage))
                .preferredColorScheme(AppTheme(rawValue: appThemeRaw)?.colorScheme)
        }
        .modelContainer(for: [Book.self, ReadingSession.self])
    }
}
