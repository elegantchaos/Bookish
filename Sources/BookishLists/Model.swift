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
    let items: Int
    
    init(selection: String?, context: NSManagedObjectContext) {
        if selection == .allBooksID {
            items = CDRecord.countOfKind(.book, in: context)
            books = items
        } else if let id = selection, let contents = CDRecord.withId(id, in: context)?.contents {
            items = contents.count
            books = contents.filter({ $0.kindCode == CDRecord.Kind.book.rawValue }).count
        } else {
            books = 0
            items = 0
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
    
    func makeDefaultFields() -> FieldList {
        let list = FieldList()
        list.addField(name: "added", kind: .date)
        list.addField(name: "published", kind: .date)
        list.addField(name: "asin", kind: .string)
        list.addField(name: "isbn", kind: .string)
        return list
    }
    
    lazy var defaultFields = makeDefaultFields()
}
