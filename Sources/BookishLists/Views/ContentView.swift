// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporter

struct ContentView: View {
    @EnvironmentObject var model: Model
    @Environment(\.managedObjectContext) var managedObjectContext
    @EnvironmentObject var sheetController: SheetController
    @State var importRequested = false

    var body: some View {
        SheetControllerHost {
                NavigationView {
                    RootIndexView(selection: $model.selection)
                        .navigationTitle(model.appName)
                        .navigationBarItems(
                            leading: EditButton(),
                            trailing:
                                Menu() {
                                    Button(action: handleAddList) { Text("New List") }
                                    Button(action: handleAddGroup) { Text("New Group") }
                                    Menu("Import…") {
                                        Button(action: handleRequestImport) { Text("From Delicious Library") }
                                    }
                                } label: {
                                    Image(systemName: "ellipsis.circle")
                                }
                        )
                }
                .navigationBarTitleDisplayMode(.automatic)
                .fileImporter(isPresented: $importRequested, allowedContentTypes: [.xml], onCompletion: model.handlePerformImport)
                .toolbar {
                    ToolbarItem(placement: .bottomBar) {
                        Spacer()
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        if let progress = model.importProgress {
                            ProgressView("Importing", value: progress)
                        }
                    }
                    
                    ToolbarItem(placement: .bottomBar) {
                        Button(action: handlePreferences) {
                            Label("Preferences", systemImage: "gear")
                        }
                    }
                }
            
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
        importRequested = true
    }
    

    func handlePreferences() {
        sheetController.show {
            PreferencesView()
        }
    }
}

struct RootIndexView: View {
    @Environment(\.editMode) var editMode
    @Binding var selection: UUID?

    var body: some View {
        VStack {
                if editMode?.wrappedValue == .active {
                    EditableListIndexView(selection: $selection)
                } else {
                    ListIndexView(selection: $selection)
                }
            
            if let uuid = selection {
                Text(uuid.uuidString)
            }


        }
    }
}
