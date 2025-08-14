import Foundation
import SwiftData

@Model
final class Book {
    @Attribute(.unique) var id: UUID
    var title: String
    var author: String?
    var totalPages: Int
    var createdAt: Date
    // NEW:
    var rating: Int       // 0...5
    var notes: String     // free text

    @Relationship(deleteRule: .cascade, inverse: \ReadingSession.book)
    var sessions: [ReadingSession]

    init(title: String, author: String? = nil, totalPages: Int) {
        self.id = UUID()
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.author = author?.trimmingCharacters(in: .whitespacesAndNewlines)
        self.totalPages = max(0, totalPages)
        self.createdAt = Date()
        self.sessions = []
        self.rating = 0
        self.notes = ""
    }

    var pagesRead: Int { sessions.reduce(0) { $0 + max(0, $1.pagesRead) } }

    var progress: Double {
        guard totalPages > 0 else { return 0 }
        return min(1.0, Double(pagesRead) / Double(totalPages))
    }

    var lastActivityDate: Date? {
        sessions.sorted(by: { $0.date > $1.date }).first?.date
    }
}

@Model
final class ReadingSession {
    var id: UUID
    var date: Date
    var pagesRead: Int
    @Relationship var book: Book?

    init(date: Date = Date(), pagesRead: Int, book: Book) {
        self.id = UUID()
        self.date = date
        self.pagesRead = max(0, pagesRead)
        self.book = book
    }
}
