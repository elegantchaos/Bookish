// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporter

struct ContentView: View {
    @EnvironmentObject var importController: ImportController
    @EnvironmentObject var statusController: StatusController
    
    var body: some View {
        SheetControllerHost {
            NavigationView {
                RootIndexView()
            }
            .fileImporter(isPresented: $importController.importRequested, allowedContentTypes: importController.importContentTypes, onCompletion: importController.handlePerformImport)
            .navigationBarTitleDisplayMode(.automatic)
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    HStack {
                        if let progress = importController.importProgress {
                            ProgressView(progress.label, value: Double(progress.count), total: Double(progress.total))
                        } else {
                            Spacer()
                            UndoView()
                            RedoView()
                        }
                    }
                }
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
