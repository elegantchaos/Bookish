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

class ImportProgress: ObservableObject {
    let count: Int
    let name: String
    let list: CDList
    let context: NSManagedObjectContext
    let completion: () -> ()
    
    @Published var done: Int
    
    init(name: String, count: Int, context: NSManagedObjectContext, completion: @escaping () -> ()) {
        self.name = name
        self.count = count
        self.done = 0
        self.context = context
        self.completion = completion
        self.list = CDList(context: context)
        
        list.name = "Imported from Delicious Library"
        list.container = CDList.named("Imports", in: context)
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
    @Published var selection: UUID?
    
    
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
        for entity in ["CDBook", "CDList", "CDProperty"] {
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
                url.accessSecurityScopedResource { url in
                    importer.importFrom(url, monitor: self)
                }

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
    
    func finishImport() {
        importProgress?.completion()
        onMainQueue {
            self.importProgress = nil
            self.save()
        }
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
        stack.onBackground { context, completion in
            let importProgress = ImportProgress(name: "Imported from Delicious Library", count: count, context: context, completion: completion)
            onMainQueue {
                self.importProgress = importProgress
                self.selection = importProgress.list.id
            }
        }
    }
    
    func session(_ session: ImportSession, didImport item: Any) {
        if let progress = importProgress, let importedBook = item as? DeliciousLibraryImportSession.Book {
            let context = progress.context
            context.perform {
                let book: CDBook
                if let id = UUID(uuidString: importedBook.id) {
                    book = CDBook.withId(id, in: context)
                } else {
                    book = CDBook.named(importedBook.title, in: context)
                }
                
                book.name = importedBook.title
                book.imageURL = importedBook.images.first
                book.merge(properties: importedBook.raw)
                progress.list.add(book)
                onMainQueue {
                    progress.done += 1
                    print(progress.done)
                }
            }
        }
    }
    
    func sessionDidFinish(_ session: ImportSession) {
        importProgress?.context.perform {
            self.finishImport()
        }
    }
    
    func sessionDidFail(_ session: ImportSession) {
        importProgress?.context.perform {
            print("Import failed!") // TODO: handle error(s)
            self.finishImport()
        }
    }

}
