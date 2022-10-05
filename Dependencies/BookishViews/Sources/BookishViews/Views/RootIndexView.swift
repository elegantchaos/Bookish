// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

struct RootIndexView: View {
    @EnvironmentObject var model: ModelController
    @SceneStorage("rootSelection") var selection: String?

    let kinds: [CDRecord.Kind] = [.book, .person, .publisher, .series]
    let predicate = NSPredicate(format: "kindCode == \(CDRecord.Kind.root.rawValue)")

    var body: some View {
        traceChanges()
        
        return VStack {
            VStack {
                List(selection: $selection) {
                    KindIndexesListView(kinds: kinds, selection: $selection)
                    RecordIndexView(predicate: predicate, selection: $selection)
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
