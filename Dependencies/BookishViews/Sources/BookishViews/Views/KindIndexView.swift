// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/01/2021.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import SwiftUI
import SwiftUIExtensions
import ThreadExtensions

struct KindIndexView: View {
    @EnvironmentObject var model: ModelController
    @Environment(\.editMode) var editMode
    @State var selection: Set<String> = []
    
    
    @State var filter: String = ""

    let predicate: NSPredicate
    let title: String
    
    init(kind: RecordKind) {
        self.title = "root.\(kind)".localized
        self.predicate = NSPredicate(format: "kindCode == \(kind.rawValue)")
    }
    
    var body: some View {
        let isEditing = editMode.isEditing

        List(selection: $selection) {
            FilteredRecordListView(predicate: predicate, filter: $filter, onDelete: handleDelete)
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
                    AllBooksActionsMenu()
                }
            }
        }
    }
    
    func handleDelete(_ items: IndexSet?, records: FetchedResults<CDRecord>) {
           if let items = items {
               items.forEach { index in
                   let book = records[index]
                   model.delete(book)
               }
           }
       }
}
