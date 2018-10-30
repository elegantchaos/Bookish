// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import BookishModel
import CoreData

class DeliciousLibraryImporter: Importer {
    
    init(manager: ImportManager) {
        super.init(name: "Delicious Library", source: .userSpecifiedFile, manager: manager)
    }
    
    override func makeSession(importing url: URL, into context: NSManagedObjectContext, completion: @escaping ImportSession.Completion) -> ImportSession {
        return DeliciousLibraryImportSession(importer: self, context: context, url: url, completion: completion)
    }
}

class DeliciousLibraryImportSession: ImportSession {
    typealias Record = [String:Any]
    typealias RecordList = [Record]

    var people: [String:Person] = [:]
    
    let formatsToSkip = ["Audio CD", "Audio CD Enhanced", "Audio CD Import", "Video Game", "VHS Tape"]
    
    override func run() {
        
        if let data = try? Data(contentsOf: url) {
            if let list = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? RecordList {
                for record in list {
                    process(record: record, context: context)
                }
            }
        }
    }
    
    func process(record: Record, context: NSManagedObjectContext) {
        let format = record["formatSingularString"] as? String
        if (format == nil || !formatsToSkip.contains(format!)) {
            if let title = record["title"] as? String, let creators = record["creatorsCompositeString"] as? String {
                let book = Book(context: context)
                book.name = title
                book.subtitle = record["subtitle"] as? String
                book.importDate = Date()
                book.importUUID = record["uuid"] as? UUID
                if let isbn = record["isbn"] as? String {
                    let trimmed = isbn.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    if trimmed.count > 10 {
                        book.isbn13 = trimmed
                    } else {
                        book.isbn10 = trimmed
                    }
                }
                
                book.ean = record["ean"] as? String
                book.asin = record["asin"] as? String
                book.dewey = record["deweyDecimal"] as? String

                book.added = record["creationDate"] as? Date
                book.modified = record["lastModificationDate"] as? Date
                book.published = record["publishDate"] as? Date
                
                book.importRaw = record.description
                
                book.format = format
                
                if let url = (record["coverImageLargeURLString"] as? String) ?? (record["coverImageMediumURLString"] as? String) ?? (record["coverImageSmallURLString"] as? String) {
                    book.imageURL = url
                }
                
                let author: Person
                if creators != "", let cached = people[creators] {
                    author = cached
                } else {
                    author = Person(context: context)
                    author.name = creators
                    people[creators] = author
                }
                
                let role = author.role(as: Role.Default.authorName)
                role.addToBooks(book)
            }
        }
    }
}
