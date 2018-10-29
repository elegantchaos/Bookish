// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import BookishModel
import CoreData

class DeliciousLibraryImporter: Importer {
    typealias Record = [String:Any]
    typealias RecordList = [Record]
    
    init(manager: ImportManager) {
        super.init(name: "Delicious Library", source: .userSpecifiedFile, manager: manager)
    }
    
//    override var canImportFromDefaultLocation: Bool {
//        // ~/Library/Containers/Data/Library/Application\ Support/Delicious\ Library\ 3/
//
//        for library in FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask) {
//            let containers = library.appendingPathComponent("containers")
//            let delicious = containers.appendingPathComponent("com.delicious-monster.library3")
//            let data = delicious.appendingPathComponent("Data").appendingPathComponent("Application Support").appendingPathComponent("Delicious Library 3")
//        }
//        return true
//    }
    
    override func run(with url: URL, for collection: NSManagedObjectContext) {
        
        // temporarily we always wipe out the original collection

        if let data = try? Data(contentsOf: url) {
            if let list = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? RecordList {
                for record in list {
                    process(record: record, context: collection)
                }
            }
        }
    }
    
    func process(record: Record, context: NSManagedObjectContext) {
        if let title = record["title"] as? String, let creators = record["creatorsCompositeString"] as? String {
            let book = Book(context: context)
            book.name = title
            
            book.importDate = Date()
            book.importUUID = record["uuid"] as? UUID
            book.isbn = record["isbn"] as? String
            book.ean = record["ean"] as? String
            book.asin = record["asin"] as? String
            
            
            let author = Person(context: context)
            author.name = creators
            let role = author.role(as: Role.Default.authorName)
            role.addToBooks(book)
        }
    }
}
