// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

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
                        RecordLink(list, selection: $selection)
                        
                    case let .book(book, list):
                        RecordLink(book, in: list, selection: $selection)
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
