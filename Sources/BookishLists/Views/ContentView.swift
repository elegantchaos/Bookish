// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporter
import UniformTypeIdentifiers
import CoreData

class FilePickerController: ObservableObject {
    @Published var importRequested = false
    @Published var exportRequested = false
    @Published var exportDocument: BookishInterchangeDocument?
    @Published var importContentTypes: [UTType] = []
    @Published var exportContentType: UTType = .json
    @Published private var importCompletion: ((_ result: Result<URL,Error>) -> ())?
    @Published private var exportCompletion: ((_ result: Result<URL,Error>) -> ())?

    func chooseFileToImport(completion: @escaping (_ result: Result<URL,Error>) -> ()) {
        importCompletion = completion
        importRequested = true
    }

    func chooseLocationToExport(_ document: BookishInterchangeDocument, completion: @escaping (_ result: Result<URL,Error>) -> ()) {
        exportDocument = document
        exportCompletion = completion
        exportRequested = true
    }

    func handlePerformImport(_ result: Result<URL,Error>) {
        importCompletion?(result)
        importCompletion = nil
    }

    func handlePerformExport(_ result: Result<URL,Error>) {
        exportCompletion?(result)
        exportCompletion = nil
    }

}

struct ContentView: View {
    @EnvironmentObject var fileController: FilePickerController
    @EnvironmentObject var importController: ImportController
    @EnvironmentObject var statusController: StatusController
    
    var body: some View {
        SheetControllerHost {
            NavigationView {
                RootIndexView()
            }
//            .importsItemProviders([BookishInterchangeDocument.bookishType]) { itemProviders in
//                print("blah")
//                return true
//            }
            .fileImporter(isPresented: $fileController.importRequested, allowedContentTypes: fileController.importContentTypes, onCompletion: fileController.handlePerformImport)
            .fileExporter(isPresented: $fileController.exportRequested, document: fileController.exportDocument, contentType: BookishInterchangeDocument.writableContentTypes.first!, onCompletion: fileController.handlePerformExport)
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
