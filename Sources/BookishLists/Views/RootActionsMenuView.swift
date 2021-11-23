// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporterSamples

struct RootActionsMenuView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var sheetController: SheetController

    var body: some View {
        Button(action: handleAddList) { Text("New List") }
        Button(action: handleAddGroup) { Text("New Group") }
        Button(action: handleScan) { Text("Add Books…") }
        Menu("Import") {
            Button(action: handleImportSmall) { Text("Delicious Library Small Sample") }
            Button(action: handleImportFull) { Text("Delicious Library Full Sample") }
            Button(action: handleRequestImport) { Text("From Delicious Library…") }
        }
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

    func handleRequestImport() {
        model.importRequested = true
    }

    func handleImportSmall() {
        model.importFromDelicious(sampleNamed: "DeliciousSmall")
    }

    func handleImportFull() {
        model.importFromDelicious(sampleNamed: "DeliciousFull")
    }

    func handleScan() {
        sheetController.show {
            ScannerView()
        }
    }
}

struct RootActionsMenuButton: View {
    var body: some View {
        Menu() {
            RootActionsMenuView()
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}