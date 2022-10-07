// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

extension NSPredicate {
    convenience init(kind: RecordKind) {
        self.init(format: "kindCode == \(kind.rawValue)")
    }
}
struct KindIndexView: View {
    @EnvironmentObject var model: ModelController
    @Environment(\.editMode) var editMode
    @FetchRequest var records: FetchedResults<CDRecord>
    @State var selection: Set<String> = []
    @State var filter: String = ""

    let title: String
    
    init(kind: RecordKind) {
        self.title = "root.\(kind)".localized
        let predicate = NSPredicate(format: "kindCode == \(kind.rawValue)")
        self._records = .init(entity: CDRecord.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)], predicate: predicate)
    }
    
    var body: some View {
        let isEditing = editMode.isEditing

        List(selection: $selection) {
            FilteredRecordListView(records: records, filter: $filter, onDelete: handleDelete)
        }
        .listStyle(.plain)
        .searchable(text: $filter)
        .navigationBarTitle(title, displayMode: .inline)
        .navigationBarBackButtonHidden(isEditing)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if isEditing {
                    EditButton()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                ActionsMenuButton {
                    VStack {
                        KindIndexActionsMenu(records: records, selection: $selection)
                    }
                }
            }
        }
    }
    
    func handleDelete(_ items: IndexSet?, records: FetchedResults<CDRecord>) {
           if let items = items {
               items.forEach { index in
                   let book = records[index]
                   model.delete([book])
               }
           }
       }
}
