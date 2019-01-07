// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import BookishModel
import CoreData
import JSONDump
import Logger

let deliciousChannel = Logger("DeliciousImporter")

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
    
    var cachedPeople: [String:Person] = [:]
    var cachedPublishers: [String:Publisher] = [:]
    var cachedSeries: [String:Series] = [:]
    
    let formatsToSkip = ["Audio CD", "Audio CD Enhanced", "Audio CD Import", "Video Game", "VHS Tape", "VideoGame", "DVD"]
    
    let seriesNameBookPattern = try! NSRegularExpression(pattern: "(.*)\\((.*)S[.]{0,1}\\)")
    let seriesSPattern = try! NSRegularExpression(pattern: "(.*)\\((.*)S[.]{0,1}\\)")
    let seriesPattern = try! NSRegularExpression(pattern: "(.*)\\((.*)\\)$")
    let bookIndexPatterns = [
        try! NSRegularExpression(pattern: "(.*)\\:{0,1} Bk\\.{0,1} *(\\d+)"),
        try! NSRegularExpression(pattern: "(.*)\\:{0,1} Book\\.{0,1} *(\\d+)"),
        try! NSRegularExpression(pattern: "(.*)\\:{0,1} No\\.{0,1} *(\\d+)")
        ]

        
    override func run() {
        if let data = try? Data(contentsOf: url) {
            if let list = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? RecordList {
                for record in list {
                    process(record: record)
                }
            }
        }
    }
    
    private func process(record: Record) {
        let format = record["formatSingularString"] as? String
        let formatOK = format == nil || !formatsToSkip.contains(format!)
        let type = record["type"] as? String
        let typeOK = type == nil || !formatsToSkip.contains(type!)
        if formatOK && typeOK {
            if let title = record["title"] as? String, let creators = record["creatorsCompositeString"] as? String {
                let book = Book(context: context)
                book.name = title
                book.subtitle = record["subtitle"] as? String
                book.importDate = Date()
                book.importUUID = record["uuid"] as? UUID
                if let isbn = record["isbn"] as? String {
                    let trimmed = isbn.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                    book.isbn = trimmed
                }
                
                if let height = record["boxHeightInInches"] as? Double, height > 0 {
                    book.height = height
                }

                if let width = record["boxWidthInInches"] as? Double, width > 0 {
                    book.width = width
                }

                if let length = record["boxLengthInInches"] as? Double, length > 0 {
                    book.length = length
                }

                book.ean = record["ean"] as? String
                book.asin = record["asin"] as? String
                book.classification = record["deweyDecimal"] as? String
                
                book.added = record["creationDate"] as? Date
                book.modified = record["lastModificationDate"] as? Date
                book.published = record["publishDate"] as? Date
                
                book.importRaw = record.jsonDump()
                
                book.format = format
                
                if let url = (record["coverImageLargeURLString"] as? String) ?? (record["coverImageMediumURLString"] as? String) ?? (record["coverImageSmallURLString"] as? String) {
                    book.imageURL = url
                }
                
                process(creators: creators, for: book)
                
                if let publishers = record["publishersCompositeString"] as? String, !publishers.isEmpty {
                    process(publishers: publishers, for: book)
                }
                
                if let series = record["seriesSingularString"] as? String, !series.isEmpty {
                    process(series: series, index: 0, for: book)
                }
            }
        }
    }

    private func process(creators: String, for book: Book) {
        for creator in creators.split(separator: "\n") {
            let trimmed = creator.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if trimmed != "" {
                let author: Person
                if let cached = cachedPeople[trimmed] {
                    author = cached
                } else {
                    author = Person(context: context)
                    author.name = trimmed
                    cachedPeople[trimmed] = author
                }
                let relationship = author.relationship(as: Role.Default.authorName)
                relationship.addToBooks(book)
            }
        }
    }
    
    private func process(publishers: String, for book: Book) {
        for publisher in publishers.split(separator: "\n") {
            let trimmed = publisher.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if trimmed != "" {
                let publisher: Publisher
                if let cached = cachedPublishers[trimmed] {
                    publisher = cached
                } else {
                    publisher = Publisher(context: context)
                    publisher.name = trimmed
                    cachedPublishers[trimmed] = publisher
                }
                publisher.addToBooks(book)
            }
        }
    }
    
    private func process(series: String, index: Int, for book: Book) {
        let trimmed = series.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if trimmed != "" {
            let series: Series
            if let cached = cachedSeries[trimmed] {
                series = cached
            } else {
                series = Series(context: context)
                series.name = trimmed
                cachedSeries[trimmed] = series
            }
            let entry = Entry(context: context)
            entry.book = book
            entry.series = series
            if index != 0 {
                entry.index = Int16(index)
            }
        }
    }

}

