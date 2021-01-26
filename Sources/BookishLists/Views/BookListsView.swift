// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

struct BookListsView: View {
    @FetchRequest(
        entity: CDList.entity(),
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)]
    ) var lists: FetchedResults<CDList>
    
    var body: some View {
        let entries = lists.map({ ListEntry(list: $0)})
        List(entries, children: \.children) { entry in
            switch entry.kind {
                case let .list(list):
                    NavigationLink(destination: BookListView(list: list)) {
                        Label(list.name ?? "", systemImage: "books.vertical")
                    }

                case let .book(book):
                    NavigationLink(destination: BookView(book: book)) {
                        Label(book.name ?? "", systemImage: "book")
                    }
            }
        }
    }
}
