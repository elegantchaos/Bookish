// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import BookishModel
import CoreData
import JSONDump

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
    
    let seriesSPattern = try! NSRegularExpression(pattern: "(.*)\\((.*)S[.]{0,1}\\)")
    let seriesPattern = try! NSRegularExpression(pattern: "(.*)\\((.*)\\)$")
    let bookIndexPattern = try! NSRegularExpression(pattern: "(.*)\\:{0,1} Bk\\. *(\\d+)")

        
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
        if (format == nil || !formatsToSkip.contains(format!)) {
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
                
                if let publishers = record["publishersCompositeString"] as? String {
                    process(publishers: publishers, for: book)
                }
                
                if let series = inferSeries(in: record, for: book) {
                    var index = 0
                    let (series, seriesIndex) = extractIndex(from: series)
                    if seriesIndex != 0 {
                        index = seriesIndex
                    } else if let name = book.name {
                        let (name, nameIndex) = extractIndex(from: name)
                        if nameIndex != 0 {
                            book.name = name
                            index = nameIndex
                        }
                    }
                    
                    process(series: series, index: index, for: book)
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
    
    private func inferSeries(in record: Record, for book: Book) -> String? {
        if let series = record["seriesSingularString"] as? String, !series.isEmpty {
            return series
        }
        
        if let name = book.name {
            for match in seriesSPattern.matches(in: name, options: [], range: NSRange(location: 0, length: name.count)) {
                if let nameRange = Range(match.range(at: 1), in: name), let seriesRange = Range(match.range(at: 2), in: name) {
                    let adjustedName = String(name[nameRange])
                    let series = String(name[seriesRange])
                    book.name = adjustedName
                    if book.subtitle == series {
                        book.subtitle = nil
                    }
                    return series
                }
            }
            
            for match in seriesPattern.matches(in: name, options: [], range: NSRange(location: 0, length: name.count)) {
                if let nameRange = Range(match.range(at: 1), in: name), let seriesRange = Range(match.range(at: 2), in: name) {
                    let adjustedName = String(name[nameRange])
                    let series = String(name[seriesRange])
                    if series == book.subtitle {
                        book.name = adjustedName
                        book.subtitle = nil
                        return series
                    }
                }
            }
        }

        return nil
    }
    
    private func extractIndex(from series: String) -> (String, Int) {
        for match in bookIndexPattern.matches(in: series, options: [], range: NSRange(location: 0, length: series.count)) {
            if let seriesRange = Range(match.range(at: 1), in: series), let indexRange = Range(match.range(at: 2), in: series) {
                let adjustedSeries = String(series[seriesRange])
                let index = (String(series[indexRange]) as NSString).integerValue
                return (adjustedSeries, index)
            }
        }

        return (series, 0)
    }
    
    private func process(series: String, index: Int, for book: Book) {
        let trimmed = series.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        if trimmed != "" {
            let (name, index) = extractIndex(from: trimmed)
            let series: Series
            if let cached = cachedSeries[name] {
                series = cached
            } else {
                series = Series(context: context)
                series.name = name
                cachedSeries[name] = series
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

