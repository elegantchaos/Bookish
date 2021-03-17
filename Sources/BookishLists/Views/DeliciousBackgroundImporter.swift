//
//  DeliciousBackgroundImporter.swift
//  BookishLists
//
//  Created by Sam Developer on 17/03/2021.
//

import BookishImporter
import CoreData
import Foundation

class DeliciousBackgroundImporter: ObservableObject {
    let name: String
    let list: CDList
    let context: NSManagedObjectContext
    let completion: () -> ()
    
    var count = 0
    var done = 0
    
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

extension DeliciousBackgroundImporter: ImportMonitor {
    func session(_ session: ImportSession, willImportItems count: Int) {
        self.count = count
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
            book.merge(properties: importedBook.raw)
            list.add(book)
            done += 1
            print(done)
        }
    }
    
    func sessionDidFinish(_ session: ImportSession) {
        completion()
    }
    
    func sessionDidFail(_ session: ImportSession) {
        print("Import failed!") // TODO: handle error(s)
        completion()
    }

}
