// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCore
import Coercion
import Foundation
import ISBN
import Logger
import SwiftUI
import UniformTypeIdentifiers

let deliciousChannel = Channel("DeliciousImporter")


public class DeliciousLibraryImporter: Importer {
    override class public var id: String { return "com.elegantchaos.bookish.importer.delicious-library" }

    override open func makeSession(source: Any, delegate: ImportDelegate) -> ImportSession? {
        guard let url = source as? URL else { return nil }
        return DeliciousLibraryImportSession(importer: self, url: url, delegate: delegate)
    }

    public override var fileTypes: [UTType]? {
        return [.xml]
    }
}

public class DeliciousLibraryImportSession: URLImportSession {
    
    
    let formatsToSkip = ["Audio CD", "Audio CD Enhanced", "Audio CD Import", "Video Game", "VHS Tape", "VideoGame", "DVD"]
    
    let list: [[String:Any]]

    override init?(importer: Importer, url: URL, delegate: ImportDelegate) {
        // check we can parse the xml
        guard let data = try? Data(contentsOf: url), let list = (try? PropertyListSerialization.propertyList(from: data, options: [], format: nil)) as? [[String:Any]] else {
            return nil
        }
        
        // check that the records look to be in the right format
        guard let record = list.first, let _ = record["actorsCompositeString"] as? String else {
            return nil
        }
        
        self.list = list
        super.init(importer: importer, url: url, delegate: delegate)
    }
    
    func validate(_ record: [String:Any]) -> BookRecord? {
        var unprocessed = record
        let id = unprocessed.extractDeliciousID()
        let format = record["formatSingularString"] as? String
        guard format == nil || !formatsToSkip.contains(format!) else { return nil }
        
        let type = record["type"] as? String
        guard type == nil || !formatsToSkip.contains(type!) else { return nil }

        return BookRecord(unprocessed, id: id, source: importer.id)
    }
    
    override open func run() {
        delegate.session(self, willImportItems: list.count)
        for record in list {
            if var book = self.validate(record) {
                deliciousChannel.log("Started import")
                book.importFromDelicious()
                delegate.session(self, didImport: book)
            } else {
                deliciousChannel.log("skipped non-book \(record["title"] ?? record)")
            }
        }
        delegate.sessionDidFinish(self)
    }
    
}

/// Delicious Library specific extraction methods
private extension Dictionary where Key == String, Value == Any {
    mutating func extractImages(from data: inout [String:Any]) {
        var urls: [URL] = []
        for key in ["coverImageLargeURLString", "coverImageMediumURLString", "coverImageSmallURLString"] {
            if let string = data[asString: key], let url = URL(string: string.removingPercentEncoding ?? string) {
                urls.append(url)
                data.removeValue(forKey: key)
            }
        }
        
        self[BookKey.imageURLs.rawValue] = urls.map { $0.absoluteString }
    }
    
    mutating func extractDeliciousID() -> String {
        if let uuid = self[asString: "uuidString"] {
            self.removeValue(forKey: "uuidString")
            return uuid
        } else if let uuid = self[asString: "foreignUUIDString"] {
            self.removeValue(forKey: "foreignUUIDString")
            return uuid
        } else {
            return "delicious-import-\(self["title"]!)"
        }

    }
}



extension BookRecord {
    mutating func importFromDelicious() {

        var unprocessed = properties
        var processed: [String:Any] = [:]
        
        processed.extractString(forKey: "format", as: .format, from: &unprocessed)
        processed.extractString(forKey: "subtitle", as: .subtitle, from: &unprocessed)
        processed.extractString(forKey: "asin", as: .asin, from: &unprocessed)
        processed.extractString(forKey: "deweyDecimal", as: .dewey, from: &unprocessed)
        processed.extractString(forKey: "seriesSingularString", as: .series, from: &unprocessed)
        processed.extractISBN(from: &unprocessed)
        processed.extractNonZeroDouble(forKey: "boxHeightInInches", as: .height, from: &unprocessed)
        processed.extractNonZeroDouble(forKey: "boxWidthInInches", as: .width, from: &unprocessed)
        processed.extractNonZeroDouble(forKey: "boxLengthInInches", as: .length, from: &unprocessed)
        processed.extractNonZeroInt(forKey: "pages", as: .pages, from: &unprocessed)
        processed.extractNonZeroInt(forKey: "numberInSeries", as: .seriesPosition, from: &unprocessed)
        processed.extractDate(forKey: "creationDate", as: .addedDate, from: &unprocessed)
        processed.extractDate(forKey: "lastModificationDate", as: .modifiedDate, from: &unprocessed)
        processed.extractDate(forKey: "publishDate", as: .publishedDate, from: &unprocessed)
        processed.extractStringList(forKey: "creatorsCompositeString", as: .authors, from: &unprocessed)
        processed.extractStringList(forKey: "editionsCompositeString", as: .editions, from: &unprocessed)
        processed.extractStringList(forKey: "publishersCompositeString", as: .publishers, from: &unprocessed)
        processed.extractStringList(forKey: "genresCompositeString", as: .genres, from: &unprocessed)
        processed.extractStringList(forKey: "illustratorsCompositeString", as: .illustrators, from: &unprocessed)
        processed.extractImages(from: &unprocessed)

        processed[BookKey.importedID.rawValue] = unprocessed.extractDeliciousID()
        processed[BookKey.importedDate.rawValue] = Date()

        for (key, value) in unprocessed {
            if (value as? Int != 0) && (value as? String != "") {
                processed["delicious.\(key)"] = value
            } else {
                deliciousChannel.debug("Dropped empty value \(value) for \(key)")
            }
        }
        

        properties = processed
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
