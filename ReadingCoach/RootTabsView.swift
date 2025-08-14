import SwiftUI
import SwiftData

struct RootTabsView: View {
    var body: some View {
        TabView {
            BookListView()
                .tabItem {
                    Label("Library", systemImage: "books.vertical")
                }
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
    }
}
