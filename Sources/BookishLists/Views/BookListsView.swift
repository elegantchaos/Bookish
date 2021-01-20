// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

struct BookListsView: View {
    @EnvironmentObject var model: Model

    var body: some View {
        let entries = model.lists.order.map({ ListEntry(list: $0, model: model) })
        List(entries, children: \.children) { entry in
            switch entry.kind {
                case .book(let id):
                    if let binding = model.binding(forBook: id) {
                        ListItemLinkView(for: binding)
                    }
                case .list(let id):
                    if let binding = model.binding(forBookList: id) {
                        ListItemLinkView(for: binding)
                    }
            }
        }
    }
}
