// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import ISBN
import Logger

let deliciousChannel = Channel("DeliciousImporter")

extension Dictionary where Key == String, Value == Any {
    mutating func extractNonZeroDouble(forKey key: Key, as asKey: Key? = nil, from source: inout Self) {
        if let value = self[key] as? Double, value != 0 {
            self[asKey ?? key] = value
        }
        source.removeValue(forKey: key)
    }

    mutating func extractNonZeroInt(forKey key: Key, as asKey: Key? = nil, from source: inout Self) {
        if let value = self[key] as? Int, value != 0 {
            self[asKey ?? key] = value
        }
        source.removeValue(forKey: key)
    }

    mutating func extractString(forKey key: Key, as asKey: Key? = nil, from source: inout Self) {
        if let string = source[key] as? String {
            source.removeValue(forKey: key)
            self[asKey ?? key] = string
        }
    }

    mutating func extractDate(forKey key: Key, as asKey: Key? = nil, from source: inout Self) {
        if let string = source[key] as? Date {
            source.removeValue(forKey: key)
            self[asKey ?? key] = string
        }
    }

    mutating func extractStringList(forKey key: Key, separator: Character = "\n", as asKey: Key? = nil, from source: inout Self) {
        if let string = source[key] as? String {
            source.removeValue(forKey: key)
            let trimSet = CharacterSet.whitespacesAndNewlines
            self[asKey ?? key] = string.split(separator: separator).map({ $0.trimmingCharacters(in: trimSet) })
        }
    }
    
    mutating func extractISBN(as asKey: Key = .isbnKey, from source: inout Self) {
        // NB we leave the original delicious ean/isbn keys in the source so they get stored unmodified
        if let ean = source["ean"] as? String, ean.isISBN13 {
            self[asKey] = ean
        } else if let value = source["isbn"] as? String {
            let trimmed = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            self[.isbnKey] = trimmed.isbn10to13
        }
    }

    mutating func extractID(from source: inout Self) -> String {
        if let uuid = source["uuidString"] as? String {
            source.removeValue(forKey: "uuidString")
            return uuid
        } else if let uuid = source["foreignUUIDString"] as? String {
            source.removeValue(forKey: "foreignUUIDString")
            return uuid
        } else {
            return "delicious-import-\(source["title"]!)"
        }

    }
}


public class DeliciousLibraryImporter: Importer {
    override class public var identifier: String { return "com.elegantchaos.bookish.importer.delicious-library" }

    public init(manager: ImportManager) {
        super.init(name: "Delicious Library", source: .userSpecifiedFile, manager: manager)
    }
    
    override func makeSession(importing url: URL, monitor: ImportMonitor?) -> URLImportSession? {
        return DeliciousLibraryImportSession(importer: self, url: url, monitor: monitor)
    }

    public override var fileTypes: [String]? {
        return ["xml"]
    }
}

public class DeliciousLibraryImportSession: URLImportSession {
    public struct Book {
        public let id: String
        public var title: String
        public var properties: [String:Any]
        public let images: [URL]
        
        init?(info: Validated) {
            deliciousChannel.log("Started import")
            
            var unprocessed = info.properties
            var processed: [String:Any] = [:]
            
            id = processed.extractID(from: &unprocessed)
            title = info.title
            processed[.formatKey] = info.format
            
            processed.extractString(forKey: "subtitle", as: .subtitleKey, from: &unprocessed)
            processed.extractString(forKey: "asin", as: .asinKey, from: &unprocessed)
            processed.extractString(forKey: "deweyDecimal", as: .deweyKey, from: &unprocessed)
            processed.extractString(forKey: "seriesSingularString", as: .seriesKey, from: &unprocessed)
            processed.extractISBN(from: &unprocessed)
            processed.extractNonZeroDouble(forKey: "boxHeightInInches", as: .heightKey, from: &unprocessed)
            processed.extractNonZeroDouble(forKey: "boxWidthInInches", as: .widthKey, from: &unprocessed)
            processed.extractNonZeroDouble(forKey: "boxLengthInInches", as: .lengthKey, from: &unprocessed)
            processed.extractNonZeroInt(forKey: "pages", as: .pagesKey, from: &unprocessed)
            processed.extractNonZeroInt(forKey: "numberInSeries", as: .seriesPositionKey, from: &unprocessed)
            processed.extractDate(forKey: "creationDate", as: .addedDateKey, from: &unprocessed)
            processed.extractDate(forKey: "lastModificationDate", as: .modifiedDateKey, from: &unprocessed)
            processed.extractDate(forKey: "publishDate", as: .publishedDateKey, from: &unprocessed)
            processed.extractStringList(forKey: "creatorsCompositeString", as: .authorsKey, from: &unprocessed)
            processed.extractStringList(forKey: "publishersCompositeString", as: .publishersKey, from: &unprocessed)
            processed.extractStringList(forKey: "genresCompositeString", as: .genresKey, from: &unprocessed)
            processed.extractStringList(forKey: "illustratorsCompositeString", as: .illustratorsKey, from: &unprocessed)

            var urls: [URL] = []
            for key in ["coverImageLargeURLString", "coverImageMediumURLString", "coverImageSmallURLString"] {
                if let string = unprocessed[key] as? String, let url = URL(string: string) {
                    urls.append(url)
                    unprocessed.removeValue(forKey: key)
                }
            }

            for (key, value) in unprocessed {
                processed["delicious.\(key)"] = value
            }
            
            images = urls
            properties = processed
        }
    }
    
    typealias Record = [String:Any]
    typealias RecordList = [Record]
    let formatsToSkip = ["Audio CD", "Audio CD Enhanced", "Audio CD Import", "Video Game", "VHS Tape", "VideoGame", "DVD"]
    
    let list: RecordList

    override init?(importer: Importer, url: URL, monitor: ImportMonitor?) {
        // check we can parse the xml
        guard let data = try? Data(contentsOf: url), let list = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? RecordList else {
            return nil
        }
        
        // check that the records look to be in the right format
        guard let record = list.first, let _ = record["actorsCompositeString"] as? String else {
            return nil
        }
        
        self.list = list
        super.init(importer: importer, url: url, monitor: monitor)
    }
    
    struct Validated {
        let format: String?
        let title: String
        let properties: [String:Any]
    }
    
    func validate(_ record: Record) -> Validated? {
        let format = record["formatSingularString"] as? String
        guard format == nil || !formatsToSkip.contains(format!) else { return nil }
        let type = record["type"] as? String
        guard type == nil || !formatsToSkip.contains(type!) else { return nil }
        guard let title = record["title"] as? String else { return nil }
        var properties = record
        properties.removeValue(forKey: "title")
        properties.removeValue(forKey: "formatSingularString")
        return Validated(format: format, title: title, properties: properties)
    }
    
    override func run() {
        let monitor = self.monitor
        monitor?.session(self, willImportItems: list.count)
        for record in list {
            if let info = self.validate(record) {
                if let book = Book(info: info) {
                    monitor?.session(self, didImport: book)
                } else {
                    deliciousChannel.log("failed to make book from \(record)")
                }
            } else {
                deliciousChannel.log("skipped non-book \(record["title"] ?? record)")
            }
        }
        monitor?.sessionDidFinish(self)
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

