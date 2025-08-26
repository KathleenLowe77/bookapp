import SwiftUI

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.en.rawValue
    @AppStorage("dailyGoal") private var dailyGoal: Int = 20
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue
    @AppStorage("notificationsEnabled") private var notificationsEnabled: Bool = false

    @State private var showDeniedAlert = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Language") {
                    Picker("App language", selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text(lang.displayName).tag(lang.rawValue)
                        }
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: $appThemeRaw) {
                        ForEach(AppTheme.allCases) { t in
                            Text(t.title).tag(t.rawValue)
                        }
                    }
                }

                Section("Daily Goal") {
                    Stepper(value: $dailyGoal, in: 0...200, step: 5) {
                        if dailyGoal > 0 {
                            Text("\(dailyGoal) pages/day")
                        } else {
                            Text("No daily goal")
                        }
                    }
                    Text("Track how many pages you read each day.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

//                Section("Reminders") {
//                    Toggle("Daily motivational reminder at 12:00", isOn: $notificationsEnabled)
//                        .onChange(of: notificationsEnabled) { _, newValue in
//                            NotificationManager.shared.setEnabledWithPermission(newValue) { granted in
//                                if !granted {
//                                    // Вернём тумблер в Off и покажем подсказку
//                                    notificationsEnabled = false
//                                    showDeniedAlert = true
//                                }
//                            }
//                        }
//                    Button("Reschedule for tomorrow 12:00") {
//                        NotificationManager.shared.rescheduleNoon()
//                    }
//                    .disabled(!notificationsEnabled)
//                }

                Section {
                    Link("Privacy Policy", destination: URL(string: "https://www.termsfeed.com/live/c2de7e32-8b09-471f-92f7-00bd836be565")!)
                    Link("Support", destination: URL(string: "https://www.termsfeed.com/live/c2de7e32-8b09-471f-92f7-00bd836be565")!)
                }
            }
            .navigationTitle("Settings")
            .alert("Notifications are disabled", isPresented: $showDeniedAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("OK", role: .cancel) { }
            } message: {
                Text("Allow notifications in iOS Settings to receive daily reminders.")
            }
        }
    }
}
