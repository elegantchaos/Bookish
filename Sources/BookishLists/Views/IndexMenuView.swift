// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporterSamples

struct IndexMenuView: View {
    @EnvironmentObject var model: Model
    @EnvironmentObject var sheetController: SheetController

    var body: some View {
        Button(action: handleAddList) { Text("New List") }
        Button(action: handleAddGroup) { Text("New Group") }
        Button(action: handleScan) { Text("Add Books…") }
        Menu("Import…") {
            Button(action: handleRequestImport) { Text("From Delicious Library") }
            Button(action: handleImportSample) { Text("Delicious Library Sample") }
        }
    }
    
    func handleAddList() {
        let list : CDList = model.add()
        if let selection = model.selection, let container = CDList.withId(selection, in: model.stack.viewContext) {
            list.container = container
        }
        model.selection = list.id
    }

    func handleAddGroup() {
        let list: CDList = model.add()
        model.selection = list.id
    }

    func handleRequestImport() {
        model.importRequested = true
    }

    func handleImportSample() {
        let url = BookishImporter.urlForSample(withName: "DeliciousSmall")
        model.stack.onBackground { context in
            let bi = DeliciousImportMonitor(model: model, context: context)
            model.importer.importFrom(url, monitor: bi)
        }
    }

    func handleScan() {
        sheetController.show {
            ScannerView()
        }
    }
}

struct IndexMenuButton: View {
    var body: some View {
        Menu() {
            IndexMenuView()
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}
