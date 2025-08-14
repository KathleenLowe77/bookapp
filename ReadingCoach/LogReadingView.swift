import SwiftUI
import SwiftData

struct LogReadingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Bindable var book: Book
    @State private var pages = ""
    @State private var date = Date()

    private var canSave: Bool { (Int(pages) ?? 0) > 0 }

    var body: some View {
        NavigationStack {
            Form {
                Section("Entry") {
                    TextField("Pages read", text: $pages)
                        .keyboardType(.numberPad)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                if book.totalPages > 0 {
                    Section("Hint") {
                        let newPages = (Int(pages) ?? 0)
                        let total = max(0, book.pagesRead + newPages)
                        let percent = book.totalPages == 0 ? 0 : Int(Double(total) / Double(book.totalPages) * 100)
                        Text("Will be \(total) of \(book.totalPages) pages (\(percent)%)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Log reading")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let count = Int(pages) ?? 0
        let session = ReadingSession(date: date, pagesRead: count, book: book)
        context.insert(session)
        try? context.save()
        dismiss()
    }
}
