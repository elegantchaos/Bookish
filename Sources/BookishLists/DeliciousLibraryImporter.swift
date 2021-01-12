// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData
import ISBN
//import JSONDump
import Logger

let deliciousChannel = Logger("DeliciousImporter")

extension Dictionary {
    func nonZeroDouble(forKey key: Key) -> Double? {
        guard let value = self[key] as? Double, value != 0 else { return nil }
        return value
    }
}

class DeliciousLibraryImporter {
    struct Book {
        let id: String
        let name: String
        let subtitle: String?
        let isbn: String?
        let asin: String?
        let format: String?
        
        let classification: String?
        
        let added: Date?
        let modified: Date?
        let published: Date?
        
        let height: Double?
        let width: Double?
        let length: Double?
        
        let raw: Record
        let images: [URL]
        
        init?(from record: Record, format: String?) {
            guard let title = record["title"] as? String, let creators = record["creatorsCompositeString"] as? String else { return nil }
            
            if let uuid = record["uuidString"] as? String {
                id = uuid
            } else if let uuid = record["foreignUUIDString"] as? String {
                id = uuid
            } else {
                id = "delicious-import-\(title)"
            }
            
            name = title
            subtitle = record["subtitle"] as? String
            
            if let ean = record["ean"] as? String, ean.isISBN13 {
                isbn = ean
            } else if let value = record["isbn"] as? String {
                let trimmed = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                isbn = trimmed.isbn10to13
            } else {
                isbn = nil
            }
            
            height = record.nonZeroDouble(forKey: "boxHeightInInches")
            width = record.nonZeroDouble(forKey: "boxWidthInInches")
            length = record.nonZeroDouble(forKey: "boxLengthInInches")
            
            asin = record["asin"] as? String
            classification = record["deweyDecimal"] as? String
            
            added = record["creationDate"] as? Date
            modified = record["lastModificationDate"] as? Date
            published = record["publishDate"] as? Date
            
            raw = record
            self.format = format
            
            var urls: [URL] = []
            for key in ["coverImageLargeURLString", "coverImageMediumURLString", "coverImageSmallURLString"] {
                if let string = record[key] as? String, let url = URL(string: string) {
                    urls.append(url)
                }
            }
            images = urls

            //                process(creators: creators, for: book)
            //
            //                if let publishers = record["publishersCompositeString"] as? String, !publishers.isEmpty {
            //                    process(publishers: publishers, for: book)
            //                }
            //
            //                if let series = record["seriesSingularString"] as? String, !series.isEmpty {
            //                    process(series: series, position: 0, for: book)
            //                }
        }
    }
    
    typealias Record = [String:Any]
    typealias RecordList = [Record]
    let formatsToSkip = ["Audio CD", "Audio CD Enhanced", "Audio CD Import", "Video Game", "VHS Tape", "VideoGame", "DVD"]
    
    var books: [String:Book] = [:]
    let list: RecordList
    
    init?(url: URL) {
        // check we can parse the xml
        guard let data = try? Data(contentsOf: url), let list = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? RecordList else {
            return nil
        }
        
        // check that the records look to be in the right format
        guard let record = list.first, let _ = record["actorsCompositeString"] as? String else {
            return nil
        }
        
        self.list = list
    }
    
    func run() {
        for record in list {
            let format = record["formatSingularString"] as? String
            let formatOK = format == nil || !formatsToSkip.contains(format!)
            let type = record["type"] as? String
            let typeOK = type == nil || !formatsToSkip.contains(type!)
            if formatOK && typeOK {
                if let book = Book(from: record, format: format) {
                    books[book.id] = book
                }
            }
        }
    }
    
    //
    //private func process(creators: String, for book: Book) {
    //    var index = 1
    //    for creator in creators.split(separator: "\n") {
    //        let trimmed = creator.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    //        if trimmed != "" {
    //            let author: Person
    //            if let cached = cachedPeople[trimmed] {
    //                author = cached
    //            } else {
    //                author = Person.named(trimmed, in: context)
    //                if author.source == nil {
    //                    author.source = DeliciousLibraryImporter.identifier
    //                    author.uuid = "\(book.uuid!)-author-\(index)"
    //                }
    //                index += 1
    //                cachedPeople[trimmed] = author
    //            }
    //            let relationship = author.relationship(as: Role.StandardName.author)
    //            relationship.add(book)
    //        }
    //    }
    //}
    
    //private func process(publishers: String, for book: Book) {
    //    for publisher in publishers.split(separator: "\n") {
    //        let trimmed = publisher.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    //        if trimmed != "" {
    //            let publisher: Publisher
    //            if let cached = cachedPublishers[trimmed] {
    //                publisher = cached
    //            } else {
    //                publisher = Publisher.named(trimmed, in: context)
    //                if publisher.source == nil {
    //                    publisher.source = DeliciousLibraryImporter.identifier
    //                }
    //                cachedPublishers[trimmed] = publisher
    //            }
    //            publisher.add(book)
    //        }
    //    }
    //}
    //
    //private func process(series: String, position: Int, for book: Book) {
    //    let trimmed = series.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    //    if trimmed != "" {
    //        let series: Series
    //        if let cached = cachedSeries[trimmed] {
    //            series = cached
    //        } else {
    //            series = Series.named(trimmed, in: context)
    //            if series.source == nil {
    //                series.source = DeliciousLibraryImporter.identifier
    //            }
    //            cachedSeries[trimmed] = series
    //        }
    //        let entry = SeriesEntry(context: context)
    //        entry.book = book
    //        entry.series = series
    //        if position != 0 {
    //            entry.position = Int16(position)
    //        }
    //    }
    //}
    
}

