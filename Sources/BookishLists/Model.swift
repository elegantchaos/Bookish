// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
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

    @Published var importProgress: Double? = nil
    @Published var status: String? = nil
    @Published var errors: [Error] = []
    
    init(stack: CoreDataStack) {
        self.stack = stack
    }
    
    var appName: String { "Bookish Lists" }
    
    func save() {
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
        stack.viewContext.delete(object)
        save()
    }
    
    func add<T>() -> T where T: ExtensibleManagedObject {
        let object = T(context: stack.viewContext)
        save()
        return object
    }
    
    func removeAllData() {
        let context = stack.viewContext
        let coordinator = stack.coordinator
        for entity in ["CDBook", "CDList"] {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try coordinator.execute(deleteRequest, with: context)
            } catch let error as NSError {
                notify(error)
            }
        }
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
            for importedBook in session.books.values {
                let book = CDBook.named(importedBook.title, in: context)
                book.name = importedBook.title
                list.addToBooks(book)
            }
            save()
        }

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
