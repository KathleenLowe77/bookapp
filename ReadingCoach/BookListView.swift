import SwiftUI
import SwiftData

struct BookListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Book.createdAt, order: .reverse) private var books: [Book]
    
    @State private var showAdd = false
    @State private var search = ""
    @AppStorage("dailyGoal") private var dailyGoal: Int = 20

    private var filteredBooks: [Book] {
        guard !search.isEmpty else { return books }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(search) ||
            ($0.author ?? "").localizedCaseInsensitiveContains(search)
        }
    }
    
    private var todayPages: Int {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return books.flatMap { $0.sessions }
            .filter { $0.date >= start && $0.date < end }
            .reduce(0) { $0 + $1.pagesRead }
    }

    private var todayProgress: Double {
        guard dailyGoal > 0 else { return 0 }
        return min(1.0, Double(todayPages) / Double(dailyGoal))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Daily goal header
                if dailyGoal > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Today's Goal")
                                .font(.headline)
                            Spacer()
                            Text("\(todayPages)/\(dailyGoal) pages")
                                .font(.subheadline).monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: todayProgress)
                    }
                    .padding()
                }

                Group {
                    if filteredBooks.isEmpty {
                        ContentUnavailableView(
                            "No Books Yet",
                            systemImage: "book.closed",
                            description: Text("Tap “Add Book” to start tracking your reading.")
                        )
                    } else {
                        List {
                            ForEach(filteredBooks) { book in
                                NavigationLink(value: book) {
                                    BookRow(book: book)
                                }
                            }
                            .onDelete(perform: deleteBooks)
                        }
                        .listStyle(.insetGrouped)
                    }
                }
            }
            .navigationTitle("Library")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAdd = true
                    } label: {
                        Label("Add Book", systemImage: "plus")
                    }
                }
            }
            .searchable(text: $search, placement: .navigationBarDrawer, prompt: "Title or author")
            .sheet(isPresented: $showAdd) {
                AddBookView()
                    .presentationDetents([.medium, .large])
            }
            .navigationDestination(for: Book.self) { book in
                BookDetailView(book: book)
            }
        }
    }

    private func deleteBooks(at offsets: IndexSet) {
        for index in offsets {
            context.delete(filteredBooks[index])
        }
        try? context.save()
    }
}

private struct BookRow: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(book.title).font(.headline)
                if let author = book.author, !author.isEmpty {
                    Text("· \(author)").foregroundStyle(.secondary)
                }
                Spacer()
                if book.totalPages > 0 {
                    Text("\(Int(book.progress * 100))%")
                        .font(.subheadline).monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            ProgressView(value: book.progress)
            HStack(spacing: 12) {
                Label("\(book.pagesRead) pages", systemImage: "book")
                if book.totalPages > 0 {
                    Text("of \(book.totalPages)")
                }
                if let last = book.lastActivityDate {
                    Label(last.formatted(date: .abbreviated, time: .omitted), systemImage: "clock")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}
