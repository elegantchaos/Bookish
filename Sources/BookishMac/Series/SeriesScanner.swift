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
    static let bookPattern = "(Book |Bk\\. |Bk\\.|Bk |No\\. |No\\.|No |)"
    
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
    
    func matchWithArticles(_ s1: String, _ s2: String) -> String? {
        if s1 == s2 {
            return s1
        }
        
        if let s = matchWithLeftArticle(s1, s2) {
            return s
        }

        if let s = matchWithLeftArticle(s2, s1) {
            return s
        }
        
        return nil
    }

    func matchWithLeftArticle(_ s1: String, _ s2: String) -> String? {
        if ("The " + s1) == s2 {
            return s1
        }
        
        if ("A " + s1) == s2 {
            return s1
        }
        
        return nil
    }

}

class SeriesBracketsSBookDetector: SeriesDetector {
    let pattern = try! NSRegularExpression(pattern: "(.*) \\((.*)S[.]{0,1}\\)")
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let extracted = pattern.firstMatch(of: name, mappings: ["name": 1, "series": 2]) {
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
        if let extracted = pattern.firstMatch(of: name, mappings: ["name": 1, "series": 2]) {
            if let matchedSeries = extracted["series"], let matchedName = extracted["name"] {
                if let series = matchWithArticles(subtitle, matchedSeries) {
                    return Result(name: matchedName, subtitle: "", series: series, index: 0)
                }
            }
        }
        return nil
    }
}

class SeriesNameBookDetector: SeriesDetector {
    let pattern = try! NSRegularExpression(pattern: "(.*?)\\:+ (.*?)\\:{0,1} \(SeriesDetector.bookPattern)(\\d+)(.*)")
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let extracted = pattern.firstMatch(of: name, mappings: ["series": 1, "name": 2, "index": 4, "remainder": 5]) {
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

class NameBookSeriesBracketsSDetector: SeriesDetector {
    let pattern = try! NSRegularExpression(pattern: "(.*?)\\:{0,1} \(SeriesDetector.bookPattern)(\\d+) \\((.*) S.\\)")
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let extracted = pattern.firstMatch(of: name, mappings: ["series": 4, "name": 1, "index": 3]) {
            if let matchedSeries = extracted["series"], let matchedName = extracted["name"], let matchedIndex = extracted["index"] {
                if !matchedSeries.isEmpty && !name.isEmpty {
                    let matchedSubtitle = subtitle.contains(matchedSeries) ? "" : subtitle
                    let index = (matchedIndex as NSString).integerValue
                    return Result(name: matchedName, subtitle: matchedSubtitle, series: matchedSeries, index: index)
                }
            }
        }
        
        return nil
    }
}

class SubtitleBookDetector: SeriesDetector {
    var pattern: NSRegularExpression { return try! NSRegularExpression(pattern: "(.*?)[:, ]+\(SeriesDetector.bookPattern)(\\d+)(.*)") }
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let extracted = pattern.firstMatch(of: subtitle, mappings: ["series": 1, "index": 3, "remainder": 4]) {
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

class SubtitleBracketsBookDetector: SubtitleBookDetector {
    override var pattern: NSRegularExpression { return try! NSRegularExpression(pattern: "\\((.*?)[:, ]+\(SeriesDetector.bookPattern)(\\d+)(.*)\\)") }
}

class SeriesScanner {
    typealias Record = [String:Any]
    typealias RecordList = [Record]
    
    
    var cachedPeople: [String:Person] = [:]
    var cachedPublishers: [String:Publisher] = [:]
    var cachedSeries: [String:Series] = [:]
    
    let context: NSManagedObjectContext
    
    let detectors = [ NameBookSeriesBracketsSDetector(), SeriesBracketsSBookDetector(), SeriesBracketsBookDetector(), SeriesNameBookDetector(), SubtitleBracketsBookDetector(), SubtitleBookDetector() ]
    
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
        
        var matched: Bool
        repeat {
            matched = false
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

