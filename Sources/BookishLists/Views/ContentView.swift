// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporter

struct ContentView: View {
    @EnvironmentObject var modelController: ModelController
    @EnvironmentObject var importController: ImportController
    @EnvironmentObject var statusController: StatusController
    @Environment(\.managedObjectContext) var managedObjectContext
    
    @EnvironmentObject var sheetController: SheetController
    
    var body: some View {
        let showingProgress = importController.isImporting

        SheetControllerHost {
            NavigationView {
                RootIndexView()
            }
            .fileImporter(isPresented: $importController.importRequested, allowedContentTypes: [.xml], onCompletion: importController.handlePerformImport)
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
//                ToolbarItem(placement: .bottomBar) {
//                    SelectionCountView(selection: $modelController.selection, stats: modelController.selectionStats)
//                }
                
                ToolbarItem(placement: .bottomBar) {
                    Spacer()
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if let progress = importController.importProgress {
                        ProgressView(progress.label, value: Double(progress.count), total: Double(progress.total))
                            .frame(maxWidth: 512)
                    }
                }
                
                ToolbarItem(placement: .bottomBar) {
                    if !showingProgress {
                        UndoView()
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    if !showingProgress {
                        RedoView()
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

struct SelectionCountView: View {
    @Environment(\.managedObjectContext) var context
    @Binding var selection: String?
    let stats: SelectionStats
    
    var body: some View {
        return HStack {
            if stats.items > 0 {
                Text("\(stats.items) items")
            }
//
//            if stats.books > 0 {
//                Text("\(stats.books) books")
//            }
        }
    }
}
