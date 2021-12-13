// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

struct RootIndexView: View {
    @EnvironmentObject var model: ModelController
    @SceneStorage("rootSelection") var selection: String?
    
    @FetchRequest(
        entity: CDRecord.entity(),
        sortDescriptors: [
            NSSortDescriptor(key: "name", ascending: true)
        ],
        predicate: NSPredicate(format: "containedBy.@count == 0")
    ) var lists: FetchedResults<CDRecord>
    
    var body: some View {
        var entries = lists.map({ ListEntry(list: $0)})
        entries.insert(ListEntry(), at: 0)
        
        return VStack {
            List(selection: $model.selection) {
                ForEach(entries) { entry in
                    switch entry.kind {
                        case .allBooks:
                            NavigationLink(destination: AllBooksIndexView(), tag: .allBooksID, selection: $selection) {
                                Label("All Books", systemImage: "books.vertical")
                            }

                        case let .list(list):
                            RecordLink(list, selection: $model.selection)
                            
                        case let .book(book, list):
                            RecordLink(book, in: list, selection: $selection)
                    }
                }

                Spacer()
                
                NavigationLink(destination: PreferencesView()) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .listStyle(.plain)
            .navigationBarTitle(model.appName, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    ActionsMenuButton {
                        RootActionsMenu()
                    }
                }
            }
        }
    }
}
