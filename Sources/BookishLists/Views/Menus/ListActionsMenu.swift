// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporterSamples

struct ListActionsMenu: View {
    @EnvironmentObject var model: ModelController
    @Environment(\.managedObjectContext) var context
    @ObservedObject var list: CDRecord
    @Binding var selection: String?

    var body: some View {
        if list.canAddLists {
            AddRecordButton(container: list, kind: .list, selection: $selection)
        }
        
        if list.canAddGroups {
            AddRecordButton(container: list, kind: .group, selection: $selection)
        }

        if list.canAddLinks {
            Menu("Add Link") {
                AddLinkButton(kind: .book)
                ForEach(model.sortedRoles, id: \.self) { role in
                    AddLinkButton(kind: .person, role: role)
                }
                AddLinkButton(kind: .publisher)
                AddLinkButton(kind: .series)
            }
        }

        if list.canDelete {
            Button(action: handleDeleteList) { Label("Delete List", systemImage: "trash") }
        }
        
        EditButton()
    }
    
    func handleDeleteList() {
        model.delete(list)
    }
    
    func handleAdd() {
        let book = CDRecord(context: context)
        list.add(book)
        model.save()
    }
}
