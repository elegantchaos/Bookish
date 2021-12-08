// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

struct AllBooksIndexView: View {
    @EnvironmentObject var model: ModelController
    @FetchRequest(
        entity: CDRecord.entity(),
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        predicate: NSPredicate(format: "kindCode == \(CDRecord.Kind.book.rawValue)")
    ) var books: FetchedResults<CDRecord>

    @State var selectedBook: String?
    @State var filter: String = ""

    var body: some View {
        return List(selection: $selectedBook) {
            ForEach(books) { book in
                if filter.isEmpty || book.name.contains(filter) {
                    RecordLink(book, selection: $selectedBook)
                }
            }
            .onDelete(perform: handleDelete)
        }
        .navigationBarTitle("All Books", displayMode: .inline)
        .searchable(text: $filter)
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ActionsMenuButton {
                    AllBooksActionsMenu()
                }
            }
        }
    }
 
    func handleDelete(_ items: IndexSet?) {
        if let items = items {
            items.forEach { index in
                let book = books[index]
                model.delete(book)
            }
        }
    }
}
