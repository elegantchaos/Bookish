// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

struct BookInList {
    let book: CDBook
    let list: CDList?
    
    init(_ book: CDBook, in list: CDList? = nil) {
        self.book = book
        self.list = list
    }
}

extension BookInList: Identifiable {
    var id: UUID { book.id }
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

struct IndexView: View {
    @FetchRequest(
        entity: CDList.entity(),
        sortDescriptors: [
            NSSortDescriptor(key: "name", ascending: true)
        ],
        predicate: NSPredicate(format: "container == null")
    ) var lists: FetchedResults<CDList>
    
    @Binding var selection: UUID?
    
    var body: some View {
        var entries = lists.map({ ListEntry(list: $0)})
        entries.insert(ListEntry(), at: 0)
        
        return VStack {
            List(entries, children: \.children, selection: $selection) { entry in
                switch entry.kind {
                    case .allBooks:
                        NavigationLink(destination: AllBooksView()) {
                            Label("All Books", systemImage: "books.vertical")
                        }
                    case let .list(list):
                        OLinkView(list, selection: $selection)
                    case let .book(book, list):
                        LinkView(BookInList(book, in: list), selection: $selection)
                }
            }
            
        }
    }
    
//    static func query() -> NSFetchRequest<CDList> {
//        let request: NSFetchRequest<CDList> = CDList.fetchRequest()
//        request.sortDescriptors = [
//            NSSortDescriptor(key: "name", ascending: true)
//        ]
//        request.predicate = NSPredicate(format: "container == null")
//        request.que
//    ) var lists: FetchedResults<CDList>
//
//    }
}


struct EditableListIndexView: View {
    @EnvironmentObject var model: Model
    @Environment(\.managedObjectContext) var context
    @FetchRequest(
        entity: CDList.entity(),
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) var lists: FetchedResults<CDList>

    @Binding var selection: UUID?

    var body: some View {
        List(lists, selection: $selection) { list in
            ForEach(lists) { list in
                if !list.isDeleted {
                    LinkView(list, selection: $selection)
                }
            }
            .onDelete(perform: handleDelete)
        }
    }
    
    func handleDelete(_ items: IndexSet?) {
        if let items = items {
            items.forEach { index in
                let list = lists[index]
                model.delete(list)
            }
        }
    }
}
