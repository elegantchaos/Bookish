// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SwiftUIExtensions

extension [NSSortDescriptor] {
    static let defaultSort = [NSSortDescriptor(key: "name", ascending: true)]
}

struct RootIndexView: View {
    @EnvironmentObject var model: ModelController
    @EnvironmentObject var navigation: NavigationController
    @SceneStorage("rootSelection") var selection: String?
    @FetchRequest(entity: CDRecord.entity(), sortDescriptors: .defaultSort, predicate: .isRootView) var records: FetchedResults<CDRecord>

    let kinds: [RecordKind] = [.book, .person, .organisation, .series]

    var body: some View {
        traceChanges()
        
        return VStack {
            VStack {
                List(selection: $selection) {
                    KindIndexesListView(kinds: kinds)
                    FilteredRecordListView(records: records, filter: .constant(""))
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

extension NSPredicate {
    /// True for records of kind `.root`.
    static let isRootView: NSPredicate = .init(format: "kindCode == \(RecordKind.root.rawValue)")
}
