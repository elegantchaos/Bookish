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
    @EnvironmentObject var sheetController: SheetController
    @ObservedObject var list: CDRecord
    
    var body: some View {
        Button(action: handleAdd) { Label("New Book", systemImage: "plus") }
        Button(action: handleDeleteList) { Label("Delete List", systemImage: "trash") }
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
