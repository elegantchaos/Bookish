// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

struct KindIndexView: View {
    @EnvironmentObject var model: ModelController
    @Environment(\.editMode) var editMode
    @SceneStorage var selection: String?
    @State var editSelection = Set<String>()
    @Namespace var namespace
    
    @FetchRequest var books: FetchedResults<CDRecord>
    
    @State var filter: String = ""
    
    init(kind: CDRecord.Kind) {
        let sort = [NSSortDescriptor(key: "name", ascending: true)]
        let predicate = NSPredicate(format: "kindCode == \(kind.rawValue)")
        self._books = .init(entity: CDRecord.entity(), sortDescriptors: sort, predicate: predicate)
        self._selection = .init("\(kind.allItemsTag).selection")
    }
    
    var body: some View {
        let isEditing = editMode.isEditing

        List(selection: isEditing ? $editSelection : singleSelection) {
            ForEach(books) { book in
                if filter.isEmpty || book.name.contains(filter) {
                    if isEditing {
                        RecordLabel(record: book)
                    } else {
                        RecordLink(book, selection: $selection)
                    }
                }
            }
            .onDelete(perform: handleDelete)
        }
        .listStyle(.plain)
        .searchable(text: $filter)
        .navigationBarTitle("root.books", displayMode: .inline)
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
    
    var singleSelection: Binding<Set<String>> {
        return Binding {
            return .init(self.selection.map { [$0] } ?? [])
        } set: { newSelection in
            self.selection = newSelection.first
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
