// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

struct AllBooksView: View {
    @EnvironmentObject var model: Model
    @FetchRequest(
        entity: CDBook.entity(),
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) var books: FetchedResults<CDBook>

    @State var selectedBook: String?
    @State var filter: String = ""

    var body: some View {
        
        return List(selection: $selectedBook) {
            ForEach(books) { book in
                if filter.isEmpty || book.name.contains(filter) {
                    LinkView(BookInList(book), selection: $selectedBook)
                }
            }
            .onDelete(perform: handleDelete)
        }
        .searchable(text: $filter)
        .listStyle(.plain)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EditButton()
            }
            
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("All Books")
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: handleAdd) { Image(systemName: "plus") }
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
    
    func handleAdd() {
        let _ : CDBook = model.add()
    }
}
