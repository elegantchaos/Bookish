// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporterSamples

struct RootActionsMenu: View {
    @EnvironmentObject var model: ModelController

    var body: some View {
        Button(action: handleAddList) { Text("New List") }
        Button(action: handleAddGroup) { Text("New Group") }
        AddBooksButton()
        ImportMenu()
    }
    
    func handleAddList() {
        let list : CDRecord = model.add(.list)
        if let selection = model.selection, let container = CDRecord.withId(selection, in: model.stack.viewContext) {
            container.addToContents(list)
        }
        model.selection = list.id
    }

    func handleAddGroup() {
        let list: CDRecord = model.add(.group)
        model.selection = list.id
    }

}
