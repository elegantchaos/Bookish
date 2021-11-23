// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import BookishImporterSamples
import CoreData
import Images
import KeyValueStore
import Logger
import SwiftUI
import ThreadExtensions

typealias AsyncImage = Images.AsyncImage

let modelChannel = Channel("Model")

protocol JSONCodable {
    static func decode(fromJSONCoding string: String) -> Self
    var encodeAsJSON: String { get }
}

extension UUID: JSONCodable {
    static func decode(fromJSONCoding string: String) -> UUID {
        UUID(uuidString: string) ?? UUID()
    }
    
    var encodeAsJSON: String {
        self.uuidString
    }
}

struct ImportProgress {
    let count: Int
    let total: Int
    let label: String
}

struct SelectionStats {
    let books: Int
    let lists: Int
    
    init(selection: String?, context: NSManagedObjectContext) {
        if selection == .allBooksID {
            books = CDRecord.countEntities(in: context)
            lists = 0
        } else if let id = selection, let list = CDRecord.withId(id, in: context) {
            books = 0 // list.books?.count ?? 0 // TODO: fix this
            lists = list.contents?.count ?? 0
        } else {
            books = 0
            lists = 0
        }
    }
}

class Model: ObservableObject {
    
    let stack: CoreDataStack
    let importer = ImportManager()
    let images = UIImageCache()
    
    @Published var importRequested = false
    @Published var importProgress: ImportProgress?
    @Published var status: String?
    @Published var errors: [Error] = []
    @Published var selection: String? {
        willSet(newValue) {
            _selectionStats = nil
        }
    }
    
    var _selectionStats: SelectionStats?
    var selectionStats: SelectionStats {
        if _selectionStats == nil {
            _selectionStats = SelectionStats(selection: selection, context: stack.viewContext)
        }
        
        return _selectionStats!
    }
    
    init(stack: CoreDataStack) {
        self.stack = stack
        
        if let string = UserDefaults.standard.string(forKey: "selection") {
            onMainQueue {
                self.selection = string
            }
        }
    }
    
    var appName: String { "Bookish Lists" }
    
    func save() {
        UserDefaults.standard.set(selection, forKey: "selection")
        
        let context = stack.viewContext
        guard context.hasChanges else { return }
        do {
//            objectWillChange.send()
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    func delete(_ object: CDRecord) {
        print("deleting \(object.objectID)")
        if object.id == selection {
            print("cleared selection")
            selection = nil
        }
        let context = stack.viewContext
        context.perform {
            context.delete(object)
            onMainQueue {
                self.save()
            }
        }
    }
    
    func add(_ kind: CDRecord.Kind) -> CDRecord {
        let object = CDRecord(in: stack.viewContext)
        object.kind = kind
        save()
        return object
    }
    
    func removeAllData() {
        objectWillChange.send()
        let context = stack.viewContext
        let coordinator = stack.coordinator
        for entity in ["CDRecord", "CDProperty"] {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try coordinator.execute(deleteRequest, with: context)
                context.refreshAllObjects()
            } catch let error as NSError {
                notify(error)
            }
        }
        save()
    }
    
    func handlePerformImport(_ result: Result<URL,Error>) {
        switch result {
            case .success(let url):
                url.accessSecurityScopedResource { url in
                    importFromDelicious(url: url)
                }

            case .failure(let error):
                notify(error)
        }
    }
    
    func importFromDelicious(sampleNamed name: String) {
        let url = BookishImporter.urlForSample(withName: name)
        importFromDelicious(url: url)
    }
    
    func importFromDelicious(url: URL) {
        stack.onBackground { context in
            let bi = DeliciousImportMonitor(model: self, context: context)
            self.importer.importFrom(url, monitor: bi)
        }
    }
    
    func notify(_ error: Error) {
        onMainQueue {
            print(error)
            self.errors.append(error)
        }
    }
    
    func image(for book: CDRecord, usePlacholder: Bool = true) -> AsyncImage {
        if usePlacholder {
            return images.image(for: book.imageURL, default: "book")
        } else {
            return images.image(for: book.imageURL)
        }
    }
}
