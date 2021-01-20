// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

struct EditableBookListsView: View {
    @EnvironmentObject var model: Model
    var body: some View {
        List() {
            ForEach(model.lists.order, id: \.self) { id in
                if let binding = model.binding(forBookList: id) {
                    ListItemLinkView(for: binding)
                }
            }
            .onMove(perform: handleMove)
            .onDelete(perform: handleDelete)
        }
    }
    
    func handleMove(fromOffsets from: IndexSet, toOffset to: Int) {
        model.lists.move(fromOffsets: from, toOffset: to)
    }
    
    func handleDelete(_ indices: IndexSet) {
        model.lists.remove(indices)
    }
}
