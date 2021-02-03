// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

struct ListIndexView: View {
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
                        NavigationLink(destination: AllBooksView(), tag: entry.id, selection: $selection) {
                            Label("All Books", systemImage: "books.vertical")
                        }
                    case let .list(list):
                        if !list.isDeleted {
                            OLinkView(list, selection: $selection)
                        }
                    case let .book(book):
                        if !book.isDeleted {
                            OLinkView(book, selection: $selection)
                        }
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
