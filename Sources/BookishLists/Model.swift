// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import CoreData
import Images
import KeyValueStore
import Logger
import SwiftUI
import ThreadExtensions

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

class Model: ObservableObject {
    let stack: CoreDataStack
    let importer = ImportManager()
    let images = UIImageCache()
    
    @Published var importProgress: Double? = nil
    @Published var status: String? = nil
    @Published var errors: [Error] = []
    @Published var selection: UUID? = nil
    
    init(stack: CoreDataStack) {
        self.stack = stack
        
        if let string = UserDefaults.standard.string(forKey: "selection"), let uuid = UUID(uuidString: string) {
            onMainQueue {
                self.selection = uuid
            }
        }
    }
    
    var appName: String { "Bookish Lists" }
    
    func save() {
        UserDefaults.standard.set(selection?.uuidString, forKey: "selection")
        
        let context = stack.viewContext
        guard context.hasChanges else { return }
        do {
            objectWillChange.send()
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    func delete(_ object: ExtensibleManagedObject) {
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
    
    func add<T>() -> T where T: ExtensibleManagedObject {
        let object = T(context: stack.viewContext)
        save()
        return object
    }
    
    func removeAllData() {
        let context = stack.viewContext
        let coordinator = stack.coordinator
        for entity in ["CDBook", "CDList", "CDEntry"] {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            do {
                try coordinator.execute(deleteRequest, with: context)
            } catch let error as NSError {
                notify(error)
            }
        }
        save()
    }
    
    func handlePerformImport(_ result: Result<URL,Error>) {
        switch result {
            case .success(let url):
                importer.importFrom(url, monitor: self)

            case .failure(let error):
                notify(error)
        }
    }
    
    func notify(_ error: Error) {
        onMainQueue {
            print(error)
            self.errors.append(error)
        }
    }
    
    func add(importedBooksFrom session: DeliciousLibraryImportSession) {
        onMainQueue { [self] in // TODO: add on a background context?
            let context = stack.viewContext
            let list = CDList(context: context)
            list.name = "Imported from Delicious Library"
            for importedBook in session.books.values {
                let book: CDBook
                if let id = UUID(uuidString: importedBook.id) {
                    book = CDBook.withId(id, in: context)
                } else {
                    book = CDBook.named(importedBook.title, in: context)
                }
                
                book.name = importedBook.title
                book.imageURL = importedBook.images.first
                
                let entry = CDEntry(context: context)
                entry.book = book
                entry.list = list
                entry.merge(properties: importedBook.raw)
            }

            let group = CDList.named("Imports", in: context)
            list.container = group

            save()
        }

    }
    
    func image(for entry: CDEntry) -> AsyncImage {
        image(for: entry.book)
    }
    
    func image(for book: CDBook) -> AsyncImage {
        images.image(for: book.imageURL, default: "book")
    }
    
    func image(for list: CDList) -> AsyncImage {
        images.image(for: list.imageURL, default: "books.vertical")
    }
}

extension Model: ImportMonitor {
    func session(_ session: ImportSession, willImportItems count: Int) {
        onMainQueue {
            self.importProgress = 0.0
        }
    }
    
    func session(_ session: ImportSession, willImportItem label: String, index: Int, of count: Int) {
        onMainQueue {
            self.importProgress = Double(index) / Double(count)
        }
    }
    
    func sessionDidFinish(_ session: ImportSession) {
        onMainQueue {
            self.importProgress = nil
        }
        if let session = session as? DeliciousLibraryImportSession {
            self.add(importedBooksFrom: session)
        }
    }
    
    func sessionDidFail(_ session: ImportSession) {
        importProgress =  nil
    }

}
