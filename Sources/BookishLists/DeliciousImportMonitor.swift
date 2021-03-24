// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/03/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import CoreData
import Foundation
import ThreadExtensions

class DeliciousImportMonitor: ObservableObject {
    let model: Model
    let list: CDList
    let allPeople: CDList
    let allPublishers: CDList
    let context: NSManagedObjectContext
    
    var count = 0
    var done = 0
    var intervals: TimeInterval = 0
    
    init(model: Model, context: NSManagedObjectContext) {
        self.model = model
        self.context = context
        self.list = CDList(context: context)
        self.allPeople = CDList.allPeople(in: context)
        self.allPublishers = CDList.allPublishers(in: context)

        let date = Date()
        let formatted = DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none)
        list.name = "Delicious Library \(formatted)"
        list.container = CDList.allImports(in: context)
        list.set(date, forKey: "imported")
    }
}

extension DeliciousImportMonitor: ImportMonitor {
    func session(_ session: ImportSession, willImportItems count: Int) {
        self.count = count
        self.intervals = Date.timeIntervalSinceReferenceDate
        report(label: "Importing…")
    }
    
    func session(_ session: ImportSession, didImport item: Any) {
        if let importedBook = item as? DeliciousLibraryImportSession.Book {
            let book: CDBook
            if let id = UUID(uuidString: importedBook.id) {
                book = CDBook.withId(id, in: context)
            } else {
                book = CDBook.named(importedBook.title, in: context)
            }
            
            book.name = importedBook.title
            book.imageURL = importedBook.images.first
            book.merge(properties: importedBook.properties)
            list.add(book)
            done += 1

            let now = Date.timeIntervalSinceReferenceDate
            let elapsed = now - intervals
            if elapsed > 0.1 {
                intervals = now
                report(label: "Importing: \(importedBook.title)")
            }
            
            if let authors = importedBook.properties[.authorsKey] as? [String] {
                for author in authors {
                    let list = CDList.named(author, in: context)
                    list.container = allPeople
                    list.add(book)
                }
            }

            if let publishers = importedBook.properties[.publishersKey] as? [String] {
                for publisher in publishers {
                    let list = CDList.named(publisher, in: context)
                    list.container = self.allPublishers
                    list.add(book)
                }
            }

        }
    }
    
    func sessionDidFinish(_ session: ImportSession) {
        cleanup()
    }
    
    func sessionDidFail(_ session: ImportSession) {
        print("Import failed!") // TODO: handle error(s)
        cleanup()
    }

    func report(label: String) {
        let progress = ImportProgress(count: done, total: count, label: label)
        onMainQueue {
            self.model.importProgress = progress
        }
    }
    
    func save() {
        do {
            try context.save()
        } catch {
            print("Failed to save changes to background context")
        }
    }
    
    func cleanup() {
        report(label: "Saving…")
        save()
        onMainQueue {
            self.model.save()
            self.model.importProgress = nil
        }
    }
}
