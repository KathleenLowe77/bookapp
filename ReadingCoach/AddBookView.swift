import SwiftUI
import SwiftData

struct AddBookView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var title = ""
    @State private var author = ""
    @State private var totalPages = ""
    @State private var rating: Int = 0
    @State private var notes: String = ""
    @State private var showInvalidNumberAlert = false

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Book") {
                    TextField("Title (required)", text: $title)
                        .textInputAutocapitalization(.words)
                    TextField("Author", text: $author)
                        .textInputAutocapitalization(.words)
                    TextField("Total pages", text: $totalPages)
                        .keyboardType(.numberPad)
                        .onChange(of: totalPages) { newValue in
                            if !newValue.isEmpty && Int(newValue) == nil {
                                showInvalidNumberAlert = true
                                totalPages = newValue.filter { $0.isNumber }
                            }
                        }
                }
                Section("Rating") {
                    StarRatingView(rating: $rating)
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                }
            }
            .alert(NSLocalizedString("InvalidNumberMessage", comment: "Alert message when non-numeric input entered"), isPresented: $showInvalidNumberAlert) {
                Button(NSLocalizedString("OK", comment: "OK button")) {
                    showInvalidNumberAlert = false
                }
            }
            .navigationTitle("Add Book")
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
        let pages = Int(totalPages) ?? 0
        let book = Book(title: title,
                        author: author.isEmpty ? nil : author,
                        totalPages: max(0, pages))
        // если у тебя есть рейтинг/заметки в форме — не забудь
        // book.rating = max(0, min(5, rating))
        // book.notes = notes

        context.insert(book)
        do {
            try context.save()
            dismiss()
        } catch {
            // подсветит причину, если снова что-то пойдёт не так
            assertionFailure("SwiftData save failed: \(error)")
            print("SwiftData save failed:", error)
        }
    }

}
