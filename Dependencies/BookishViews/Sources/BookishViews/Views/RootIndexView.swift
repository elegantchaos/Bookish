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
        predicate: NSPredicate(format: "kindCode == \(CDRecord.Kind.root.rawValue)")
    ) var lists: FetchedResults<CDRecord>
    
    var body: some View {
        traceChanges()

        let kinds: [CDRecord.Kind] = [.book, .person, .publisher, .series]
        
        return VStack {
            VStack {
                List(selection: $selection) {
                    ForEach(kinds) { kind in
                        NavigationLink(tag: kind.allItemsTag, selection: $selection) {
                            KindIndexView(kind: kind)
                        } label: {
                            Label(kind.pluralLabel, systemImage: kind.indexIconName)
                        }
                    }

                    ForEach(lists) { list in
                        RecordLink(list, selection: $selection)
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            List {
                NavigationLink(destination: PreferencesView()) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .frame(height: 64) // TODO: this should be dynamic
        }
        .listStyle(.plain)
        .navigationBarTitle(model.appName, displayMode: .inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ActionsMenuButton {
                    RootActionsMenu(selection: $selection)
                }
            }
        }
        
    }
}
