import SwiftUI
import SwiftData

struct BookDetailView: View {
    @Environment(\.modelContext) private var context
    @State private var showLog = false
    @State private var confirmDelete = false

    var book: Book

    var body: some View {
        List {
            // MARK: Book header + rating + progress
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(book.title)
                            .font(.title2.bold())
                        if (book.isFavorite) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(.yellow)
                        }
                        Spacer()
                        if book.totalPages > 0 {
                            Text("\(Int(book.progress * 100))%")
                                .font(.headline)
                                .monospacedDigit()
                        }
                    }

                    if let author = book.author, !author.isEmpty {
                        Text(author)
                            .foregroundStyle(.secondary)
                    }

                    // Rating (editable inline)
                    StarRatingView(
                        rating: Binding(
                            get: { book.rating },
                            set: { newValue in
                                book.rating = max(0, min(5, newValue))
                                try? context.save()
                            }
                        )
                    )

                    // Progress text
                    if book.totalPages > 0 {
                        ProgressView(value: book.progress)
                        Text(
                            String(
                                format: NSLocalizedString("%d of %d pages", comment: "progress format"),
                                book.pagesRead,
                                book.totalPages
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    } else {
                        Text(
                            String(
                                format: NSLocalizedString("%d pages read", comment: "pages read format"),
                                book.pagesRead
                            )
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text("Book")
            }

            // MARK: Notes
            Section {
                if book.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("No notes yet")
                        .foregroundStyle(.secondary)
                } else {
                    Text(book.notes)
                        .textSelection(.enabled)
                }
                NavigationLink("Edit notes") {
                    NotesEditorView(book: book)
                }
            } header: {
                Text("Notes")
            }

            // MARK: Reading log
            Section {
                if book.sessions.isEmpty {
                    Text("No entries yet. Tap the + button in the top right.")
                        .foregroundStyle(.secondary)
                } else {
                    let sorted = book.sessions.sorted(by: { $0.date > $1.date })
                    ForEach(sorted) { session in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("+" + String(format: NSLocalizedString("%d pages", comment: "pages"), session.pagesRead))
                                    .font(.headline)
                                    .monospacedDigit()
                                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                    }
                    .onDelete { offsets in
                        let sorted = book.sessions.sorted(by: { $0.date > $1.date })
                        for index in offsets { context.delete(sorted[index]) }
                        try? context.save()
                    }
                }
            } header: {
                Text("Reading Log")
            }


            // MARK: Manage
            Section {
                NavigationLink("Edit Book") {
                    EditBookForm(book: book)
                }
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    Label("Delete Book", systemImage: "trash")
                }
            } header: {
                Text("Manage")
            }
        }
        .navigationTitle("Book")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    book.isFavorite.toggle()
                    try? context.save()
                } label: {
                    Image(systemName: book.isFavorite ? "star.fill" : "star")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showLog = true
                } label: {
                    Label("Log reading", systemImage: "plus.circle.fill")
                }
            }
        }
        .sheet(isPresented: $showLog) {
            LogReadingView(book: book)
                .presentationDetents([.medium])
        }
        .alert("Delete this book?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                context.delete(book)
                try? context.save()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("All reading entries for this book will be removed.")
        }
    }
}

// MARK: - Edit form (title/author/pages + rating + notes)
private struct EditBookForm: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var book: Book

    @State private var titleText: String = ""
    @State private var authorText: String = ""
    @State private var totalText: String = ""
    @State private var ratingValue: Int = 0
    @State private var notesText: String = ""
    @State private var isFavorite: Bool = false
    @State private var showInvalidNumberAlert = false

    var body: some View {
        Form {
            Section {
                TextField("Title", text: $titleText)
                TextField("Author", text: $authorText)
                TextField("Total pages", text: $totalText)
                    .keyboardType(.numberPad)
                    .onChange(of: totalText) { newValue in
                        if !newValue.isEmpty && Int(newValue) == nil {
                            showInvalidNumberAlert = true
                            totalText = newValue.filter { $0.isNumber }
                        }
                    }
                Toggle("Favorite", isOn: $isFavorite)
            } header: {
                Text("Book")
            }

            Section {
                StarRatingView(rating: $ratingValue)
                Text(String(format: NSLocalizedString("%d of %d stars", comment: "stars format"),
                            ratingValue, 5))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } header: {
                Text("Rating")
            }

            Section {
                TextEditor(text: $notesText)
                    .frame(minHeight: 140)
                    .accessibilityLabel("Notes")
            } header: {
                Text("Notes")
            }
        }
        .alert(NSLocalizedString("Введите, пожалуйста, цифры", comment: "Invalid number input"), isPresented: $showInvalidNumberAlert) {
            Button("OK", role: .cancel) { showInvalidNumberAlert = false }
        }
        .navigationTitle("Edit Book")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
            }
        }
        .onAppear {
            titleText = book.title
            authorText = book.author ?? ""
            totalText = book.totalPages > 0 ? "\(book.totalPages)" : ""
            ratingValue = book.rating
            notesText = book.notes
            isFavorite = book.isFavorite
        }
    }

    private func save() {
        book.title = titleText.trimmingCharacters(in: .whitespacesAndNewlines)

        let cleanedAuthor = authorText.trimmingCharacters(in: .whitespacesAndNewlines)
        book.author = cleanedAuthor.isEmpty ? nil : cleanedAuthor

        book.totalPages = Int(totalText) ?? 0
        book.rating = max(0, min(5, ratingValue))
        book.notes = notesText
        book.isFavorite = isFavorite

        try? context.save()
        dismiss()
    }
}

// MARK: - Notes editor (standalone)
private struct NotesEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    var book: Book
    @State private var text = ""

    var body: some View {
        Form {
            Section {
                TextEditor(text: $text)
                    .frame(minHeight: 240)
            }
        }
        .navigationTitle("Edit notes")
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    book.notes = text
                    try? context.save()
                    dismiss()
                }
            }
        }
        .onAppear { text = book.notes }
    }
}
