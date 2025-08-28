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
            FavoritesView()
                .tabItem {
                    Label("Favorites", systemImage: "star.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
            
        }
    }
}
