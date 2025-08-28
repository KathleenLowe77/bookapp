import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var context
    @AppStorage("appTheme") private var appThemeRaw: String = AppTheme.system.rawValue
    private var appTheme: AppTheme { AppTheme(rawValue: appThemeRaw) ?? .system }

    // Only favorite books, sorted by title
    @Query private var favorites: [Book]

    init() {
        _favorites = Query(
            filter: #Predicate<Book> { $0.isFavorite == true },
            sort: [SortDescriptor(\Book.title, order: .forward)]
        )
    }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "No favorites yet",
                        systemImage: "star",
                        description: Text("Tap the star on a book to add it here.")
                    )
                } else {
                    List {
                        ForEach(favorites) { book in
                            NavigationLink(destination: BookDetailView(book: book)) {
                                HStack(spacing: 12) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(book.title)
                                            .font(.headline)
                                        if let author = book.author, !author.isEmpty {
                                            Text(author)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    book.isFavorite = false
                                    try? context.save()
                                } label: {
                                    Label("Remove", systemImage: "star.slash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Favorites")
            .background(appTheme.backgroundColor.ignoresSafeArea())
        }
    }
}
