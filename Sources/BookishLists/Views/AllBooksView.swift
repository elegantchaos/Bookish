// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

struct AllBooksView: View {
    @Environment(\.editMode) var editMode
    @State var filter: String = ""

    var body: some View {
        AllBooksContentView()
            .navigationBarTitle("All Books", displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if editMode.isEditing {
                        EditButton()
                    } else {
                        ActionsMenuButton {
                            AllBooksActionsMenu()
                        }
                    }
                }
            }
    }
}

struct AllBooksContentView: View {
    @EnvironmentObject var model: ModelController
    @Environment(\.editMode) var editMode
    @SceneStorage("allBooksSelection") var selection: String?
    @State var editSelection = Set<String>()
    @Namespace var namespace
    
    @FetchRequest(
        entity: CDRecord.entity(),
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        predicate: NSPredicate(format: "kindCode == \(CDRecord.Kind.book.rawValue)")
    ) var books: FetchedResults<CDRecord>
    
    @State var filter: String = ""
    
    var body: some View {
        if editMode.isEditing {
            List(selection: $editSelection) {
                ForEach(books) { book in
                    if filter.isEmpty || book.name.contains(filter) {
                        RecordLabel(record: book)
                            .matchedGeometryEffect(id: book.id, in: namespace)
                    }
                }
                .onDelete(perform: handleDelete)
            }
            .listStyle(.plain)
            .searchable(text: $filter)
        } else {
            List(selection: $selection) {
                ForEach(books) { book in
                    if filter.isEmpty || book.name.contains(filter) {
                        RecordLink(book, selection: $selection)
                            .matchedGeometryEffect(id: book.id, in: namespace)
                    }
                }
                .onDelete(perform: handleDelete)
            }
            .listStyle(.plain)
            .searchable(text: $filter)
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
