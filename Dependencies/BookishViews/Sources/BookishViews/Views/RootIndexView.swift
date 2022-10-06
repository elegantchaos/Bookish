// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

struct RootIndexView: View {
    @EnvironmentObject var model: ModelController
    @EnvironmentObject var navigation: NavigationController
    @SceneStorage("rootSelection") var selection: String?

    let kinds: [RecordKind] = [.book, .person, .publisher, .series]
    let predicate = NSPredicate(format: "kindCode == \(RecordKind.root.rawValue)")

    var body: some View {
        traceChanges()
        
        return VStack {
            VStack {
                List(selection: $selection) {
                    KindIndexesListView(kinds: kinds)
                    FilteredRecordListView(predicate: predicate, filter: .constant(""))
                }
            }
            .frame(maxHeight: .infinity)
            
            List {
                NavigationLink(value: String.rootPreferencesID) {
                    Label("Settings", systemImage: "gear")
                }
            }
            .listRowSeparator(.hidden)
            .frame(height: 64) // TODO: this should be dynamic
        }
        .listStyle(.plain)
        .navigationBarTitle(model.appName, displayMode: .inline)
        .standardNavigation()
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                ActionsMenuButton {
                    RootActionsMenu(selection: $selection)
                }
            }
        }
        
    }
    
    
   
}
