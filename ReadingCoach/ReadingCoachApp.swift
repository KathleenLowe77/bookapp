import SwiftUI
import SwiftData
import UserNotifications

@main
struct ReadingCoachApp: App {
    @UIApplicationDelegateAdaptor(StartMenuAppDelegate.self) var orientationDelegate

    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.en.rawValue
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false

    var body: some Scene {
        WindowGroup {
            StartMenuFlowView {
                            RootTabsView()
                    .enableRateAfterTaps() // ← your main UI
                        }
                .environment(\.locale, Locale(identifier: appLanguage))
                .preferredColorScheme(AppTheme(rawValue: appThemeRaw)?.colorScheme)
                .onAppear {
                    NotificationManager.shared.bootstrapNotifications(enabled: notificationsEnabled)
                }
        }
        .modelContainer(for: [Book.self, ReadingSession.self])
    }
}
