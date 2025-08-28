import SwiftUI
import SwiftData

@main
struct ReadingCoachApp: App {
    
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.en.rawValue
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    init() {
        
        NotificationCenter.default.post(name: Notification.Name("art.icon.loading.start"), object: nil)
        IconSettings.shared.attach()
    }
    
    var body: some Scene {
        WindowGroup {
            TabSettingsView{
            RootTabsView()
                .environment(\.locale, Locale(identifier: appLanguage))
                .preferredColorScheme(AppTheme(rawValue: appThemeRaw)?.colorScheme)
       
            }
        
            .onAppear {
                OrientationGate.allowAll = false
            }
   
        }
       
        .modelContainer(for: [Book.self, ReadingSession.self])
   
    }
    
    
    
    
    
    
    
    
    
    
    final class AppDelegate: NSObject, UIApplicationDelegate {
        func application(_ application: UIApplication,
                         supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
            if OrientationGate.allowAll {
                return [.portrait, .landscapeLeft, .landscapeRight]
            } else {
                return [.portrait]
            }
        }
    }
    
    
    
    
    
    
    
    
}







