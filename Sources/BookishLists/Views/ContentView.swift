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
    
    var body: some View {
        SheetControllerHost {
            NavigationView {
                RootIndexView(selection: $model.selection)
                    .navigationTitle(model.appName)
                    .navigationBarItems(
                        leading: EditButton(),
                        trailing: IndexMenuButton()
                    )
            }
            .fileImporter(isPresented: $model.importRequested, allowedContentTypes: [.xml], onCompletion: model.handlePerformImport)
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    SelectionCountView(selection: $model.selection, stats: model.selectionStats)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Spacer()
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if let progress = model.importProgress {
                        ProgressView(progress.label, value: Double(progress.count), total: Double(progress.total))
                            .frame(maxWidth: 512)
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
    
    func handlePreferences() {
        sheetController.show {
            PreferencesView()
        }
    }
}

struct RootIndexView: View {
    @Environment(\.editMode) var editMode
    @Binding var selection: String?
    
    var body: some View {
        VStack {
            if editMode?.wrappedValue == .active {
                EditableListIndexView(selection: $selection)
            } else {
                IndexView(selection: $selection)
            }
            
            
            
        }
    }
}

struct SelectionCountView: View {
    @Environment(\.managedObjectContext) var context
    @Binding var selection: String?
    let stats: SelectionStats
    
    var body: some View {
        return HStack {
            if stats.lists > 0 {
                Text("\(stats.lists) lists")
            }

            if stats.books > 0 {
                Text("\(stats.books) books")
            }
        }
    }
}
