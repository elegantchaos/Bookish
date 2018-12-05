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
    static let bookPattern = "(Book |Bk\\. |Bk )"
    
    struct Result {
        let name: String
        let subtitle: String
        let series: String
        let index: Int
    }
    
    func detect(name: String, subtitle: String) -> Result? {
        return nil
    }
    
    func extract(_ from: NSTextCheckingResult, string: String, matches: [String:Int]) -> [String:String] {
        var extracted: [String:String] = [:]
        for match in matches {
            if let range = Range(from.range(at: match.value), in: string) {
                extracted[match.key] = String(string[range])
            }
        }
        return extracted
    }
}

class SeriesBracketsSBookDetector: SeriesDetector {
    let pattern = try! NSRegularExpression(pattern: "(.*) \\((.*)S[.]{0,1}\\)")
    
    override func detect(name: String, subtitle: String) -> Result? {
        let range = NSRange(location: 0, length: name.count)
        if let match = pattern.firstMatch(in: name, options: [], range: range) {
            let extracted = extract(match, string: name, matches: ["name": 1, "series": 2])
            if let matchedSeries = extracted["series"], let matchedName = extracted["name"], !matchedSeries.isEmpty && !name.isEmpty {
                let matchedSubtitle = subtitle.contains(matchedSeries) ? "" : subtitle
                return Result(name: matchedName, subtitle: matchedSubtitle, series: matchedSeries, index: 0)
            }
        }
        
        return nil
    }
}

class SeriesBracketsBookDetector: SeriesDetector {
    let pattern = try! NSRegularExpression(pattern: "(.*) \\((.*)\\)$")
    
    override func detect(name: String, subtitle: String) -> Result? {
        let range = NSRange(location: 0, length: name.count)
        if let match = pattern.firstMatch(in: name, options: [], range: range) {
            let extracted = extract(match, string: name, matches: ["name": 1, "series": 2])
            if let matchedSeries = extracted["series"], let matchedName = extracted["name"], subtitle == matchedSeries {
                return Result(name: matchedName, subtitle: "", series: matchedSeries, index: 0)
            }
        }
        return nil
    }
}

class SeriesNameBookDetector: SeriesDetector {
    let pattern = try! NSRegularExpression(pattern: "(.*)\\:+ (.*)\\:{0,1} \(SeriesDetector.bookPattern)(\\d+)(.*)")
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let match = pattern.firstMatch(in: name, options: [], range: NSRange(location: 0, length: name.count)) {
            let extracted = extract(match, string: name, matches: ["series": 1, "name": 2, "index": 4, "remainder": 5])
            if let matchedSeries = extracted["series"], let matchedName = extracted["name"], let matchedIndex = extracted["index"], let remainder = extracted["remainder"] {
                if !matchedSeries.isEmpty && !name.isEmpty {
                    let matchedSubtitle = subtitle.contains(matchedSeries) ? "" : subtitle
                    let index = (matchedIndex as NSString).integerValue
                    return Result(name: matchedName + remainder, subtitle: matchedSubtitle, series: matchedSeries, index: index)
                }
            }
        }
        
        return nil
    }
}

class SubtitleBookDetector: SeriesDetector {
    let pattern = try! NSRegularExpression(pattern: "\\({0,1}(.*)\\:{0,1} \(SeriesDetector.bookPattern)(\\d+)(.*)\\){0,1}")
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let match = pattern.firstMatch(in: subtitle, options: [], range: NSRange(location: 0, length: subtitle.count)) {
            let extracted = extract(match, string: subtitle, matches: ["series": 1, "index": 3, "remainder": 4])
            if let matchedSeries = extracted["series"], let remainder = extracted["remainder"], let matchedIndex = extracted["index"] {
                if !matchedSeries.isEmpty {
                    let series = matchedSeries + remainder
                    let index = (matchedIndex as NSString).integerValue
                    return Result(name: name, subtitle: "", series: series, index: index)
                }
            }
        }
        
        return nil
    }
}

class SeriesScanner {
    typealias Record = [String:Any]
    typealias RecordList = [Record]
    
    
    var cachedPeople: [String:Person] = [:]
    var cachedPublishers: [String:Publisher] = [:]
    var cachedSeries: [String:Series] = [:]
    
    let context: NSManagedObjectContext
    
    let formatsToSkip = ["Audio CD", "Audio CD Enhanced", "Audio CD Import", "Video Game", "VHS Tape", "VideoGame", "DVD"]
    
    let detectors = [ SeriesBracketsSBookDetector(), SeriesBracketsBookDetector(), SeriesNameBookDetector(), SubtitleBookDetector() ]
    
    let seriesNameBookPattern = try! NSRegularExpression(pattern: "(.*)\\((.*)S[.]{0,1}\\)")
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
    
    public func run() {
        let books: [Book] = context.everyEntity()
        
        var matched = false
        repeat {
            for book in books {
                for detector in detectors {
                    let name = book.name ?? ""
                    let subtitle = book.subtitle ?? ""
                    if let detected = detector.detect(name: name, subtitle: subtitle) {
                        book.name = detected.name
                        book.subtitle = detected.subtitle
                        deliciousChannel.log("extracted <\(detected.name)> <\(detected.subtitle)> <\(detected.series) \(detected.index)> from <\(name)> <\(subtitle)>")
                        process(series: detected.series, index: detected.index, for: book)
                        matched = true
                    }
                }
            }
        } while (matched)
        
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

