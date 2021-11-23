// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

struct BookInList {
    let book: CDRecord
    let list: CDRecord?
    
    init(_ book: CDRecord, in list: CDRecord? = nil) {
        self.book = book
        self.list = list
    }
}

extension BookInList: Identifiable {
    var id: String { book.id }
}

extension BookInList: AutoLinked {
    var linkView: some View {
        assert(book.isDeleted == false)
        assert((list == nil) || (list!.isDeleted == false))
        
        let fields = list?.fields ?? FieldList()
        return BookView(book: book, fields: fields)
    }
    
    var labelView: some View {
        assert(book.isDeleted == false)
        return ImageOwnerLabelView(object: book)
    }
}

struct RootIndexView: View {
    @EnvironmentObject var model: Model
    
    @FetchRequest(
        entity: CDRecord.entity(),
        sortDescriptors: [
            NSSortDescriptor(key: "name", ascending: true)
        ],
        predicate: NSPredicate(format: "containedBy.@count == 0")
    ) var lists: FetchedResults<CDRecord>
    
    @Binding var selection: String?
    
    var body: some View {
        var entries = lists.map({ ListEntry(list: $0)})
        entries.insert(ListEntry(), at: 0)
        
        return VStack {
            List(entries, selection: $selection) { entry in
                switch entry.kind {
                    case .allBooks:
                        NavigationLink(destination: AllBooksIndexView(), tag: .allBooksID, selection: $selection) {
                            Label("All Books", systemImage: "books.vertical")
                        }

                        
                    case let .list(list):
                        OLinkView(list, selection: $selection)
                        
                    case let .book(book, list):
                        LinkView(BookInList(book, in: list), selection: $selection)
                }
            }
            .listStyle(.plain)
            .navigationTitle(model.appName)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                   RootActionsMenuButton()
                }
            }
        }
    }
}
