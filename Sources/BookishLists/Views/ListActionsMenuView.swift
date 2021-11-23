// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporterSamples

struct ListActionsMenuView: View {
    @EnvironmentObject var model: Model
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject var sheetController: SheetController

    let list: CDList
    
    var body: some View {
        Button(action: handleAdd) { Label("New Book", systemImage: "plus") }
        Button(action: handleDeleteList) { Label("Delete List", systemImage: "trash") }
        EditButton()
    }
    
    func handleDeleteList() {
        model.delete(list)
    }
    
    func handleAdd() {
        let book = CDList(context: context)
        list.add(book)
        model.save()
    }

}

struct ListActionsMenuButton: View {
    let list: CDList

    var body: some View {
        Menu() {
            ListActionsMenuView(list: list)
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
