// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import BookishModel
import CoreData
import JSONDump
import Logger

let seriesDetectorChannel = Logger("DeliciousImporter")

class SeriesDetector {
    typealias Record = [String:Any]
    typealias RecordList = [Record]
    
    
    var cachedPeople: [String:Person] = [:]
    var cachedPublishers: [String:Publisher] = [:]
    var cachedSeries: [String:Series] = [:]
    
    let context: NSManagedObjectContext
    
    let formatsToSkip = ["Audio CD", "Audio CD Enhanced", "Audio CD Import", "Video Game", "VHS Tape", "VideoGame", "DVD"]
    
    let seriesNameBookPattern = try! NSRegularExpression(pattern: "(.*)\\((.*)S[.]{0,1}\\)")
    let seriesSPattern = try! NSRegularExpression(pattern: "(.*)\\((.*)S[.]{0,1}\\)")
    let seriesPattern = try! NSRegularExpression(pattern: "(.*)\\((.*)\\)$")
    let bookIndexPatterns = [
        try! NSRegularExpression(pattern: "(.*)\\:{0,1} Bk\\.{0,1} *(\\d+)"),
        try! NSRegularExpression(pattern: "(.*)\\:{0,1} Book\\.{0,1} *(\\d+)"),
        try! NSRegularExpression(pattern: "(.*)\\:{0,1} No\\.{0,1} *(\\d+)")
    ]
    
    init(context: NSManagedObjectContext) {
        self.context = context
        makeCaches()
    }
    
    private func makeCaches() {
        let everySeries: [Series] = context.everyEntity()
        for series in everySeries {
            if let name = series.name {
                cachedSeries[name] = series
            }
        }

        let everyPublisher: [Publisher] = context.everyEntity()
        for publisher in everyPublisher {
            if let name = publisher.name {
                cachedPublishers[name] = publisher
            }
        }
    }
    
    private func process(record: Record) {
        let books: [Book] = context.everyEntity()
        for book in books {
            if let (series, index) = process(book: book) {
                if let entry = book.series {
                    context.delete(entry)
                }
                process(series: series, index: index, for: book)
            }
        }
    }

    private func process(book: Book) -> (String, Int)? {
        if let series = book.series?.series?.name, !series.isEmpty {
            deliciousChannel.log("Explicit series <\(series)>, book <\(book.name ?? "")> subtitle <\(book.subtitle ?? "")>")
            return extractIndex(from: series, book: book)
        }
        
        if let name = book.name {
            for match in seriesSPattern.matches(in: name, options: [], range: NSRange(location: 0, length: name.count)) {
                if let nameRange = Range(match.range(at: 1), in: name), let seriesRange = Range(match.range(at: 2), in: name) {
                    let adjustedName = String(name[nameRange])
                    let series = String(name[seriesRange])
                    book.name = adjustedName
                    deliciousChannel.log("(S.) <\(series)>, book <\(book.name ?? "")> subtitle <\(book.subtitle ?? "")>")
                    return extractIndex(from: series, book: book)
                }
            }
            
            for match in seriesPattern.matches(in: name, options: [], range: NSRange(location: 0, length: name.count)) {
                if let nameRange = Range(match.range(at: 1), in: name), let seriesRange = Range(match.range(at: 2), in: name) {
                    let adjustedName = String(name[nameRange])
                    let series = String(name[seriesRange])
                    if series == book.subtitle {
                        book.name = adjustedName
                        book.subtitle = nil
                        deliciousChannel.log("() <\(series)>, book <\(book.name ?? "")> subtitle <\(book.subtitle ?? "")>")
                        return extractIndex(from: series, book: book)
                    }
                }
            }
        }
        
        return nil
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

    private func extractIndex(from series: String, book: Book) -> (String, Int) {
        if let (extractedSeries, index) = extractIndex(from: series) {
            deliciousChannel.log("extracted index \(index) from series \(series) leaving \(extractedSeries)")
            return (extractedSeries, index)
        }
        
        if let name = book.name {
            if let (extractedName, index) = extractIndex(from: name) {
                book.name = extractedName
                deliciousChannel.log("extracted index \(index) from name \(name) leaving \(extractedName)")
                return (extractedName, index)
            }
        }
        
        if let subtitle = book.subtitle {
            if let (extractedSubtitle, index) = extractIndex(from: subtitle) {
                book.subtitle = extractedSubtitle
                deliciousChannel.log("extracted index \(index) from subtitle \(subtitle) leaving \(extractedSubtitle)")
                return (extractedSubtitle, index)
            }
        }
        
        return (series, 0)
    }
    
    private func extractIndex(from string: String) -> (String, Int)? {
        for pattern in bookIndexPatterns {
            for match in pattern.matches(in: string, options: [], range: NSRange(location: 0, length: string.count)) {
                if let seriesRange = Range(match.range(at: 1), in: string), let indexRange = Range(match.range(at: 2), in: string) {
                    let adjustedSeries = String(string[seriesRange])
                    let index = (String(string[indexRange]) as NSString).integerValue
                    return (adjustedSeries, index)
                }
            }
        }
        
        return nil
    }
    
    
}

