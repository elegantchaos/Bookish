// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporter
import UniformTypeIdentifiers
import CoreData

public struct RootView: View {
    @EnvironmentObject var model: ModelController
    @EnvironmentObject var fileController: FilePickerController
    @EnvironmentObject var importController: ImportController
    @EnvironmentObject var statusController: StatusController
    
    public init() {
    }
    
    public var body: some View {
        SheetControllerHost {
            NavigationStack {
                RootIndexView()
                    .navigationDestination(for: String.self, destination: destinationByID)
                    .navigationDestination(for: CDRecord.self, destination: destinationByRecord)
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
    
    func destinationByID(_ id: String) -> some View {
        Group {
            if id == .rootPreferencesID {
                PreferencesView()
            } else {
                EmptyView()
            }
        }
    }
    
    func destinationByRecord(_ record: CDRecord) -> some View {
//        if record.isBook {
//            return BookView(book: record, fields: list?.fields ?? model.defaultFields)
//        } else {
//
        Group {
            switch record.kind {
                case .list:
                    CustomListView(list: record, fields: model.defaultFields)
                    
                case .role:
                    LinksIndexView(list: record)
                    
                case .publisher, .series, .person:
                    BackLinksIndexView(list: record)
                    
                default:
                    ListIndexView(list: record)
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
