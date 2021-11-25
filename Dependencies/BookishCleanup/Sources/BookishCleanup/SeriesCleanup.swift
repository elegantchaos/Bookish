// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData
import Logger
import Expressions

class SeriesCleaner {
    let detectors = [ NameSeriesBookBracketsDetector(), TitleInSeriesDetector(), SeriesBracketsBookNumberDetector(), SeriesBracketsBookDetector(), NameBookSeriesBracketsSDetector(), SeriesBracketsSBookDetector(), SubtitleBookDetector(), SeriesNameBookDetector()]
    
    let bookIndexPatterns = [
        try! NSRegularExpression(pattern: "(.*)\\:{0,1} Bk\\.{0,1} *(\\d+)"),
        try! NSRegularExpression(pattern: "(.*)\\:{0,1} Book\\.{0,1} *(\\d+)"),
        try! NSRegularExpression(pattern: "(.*)\\:{0,1} No\\.{0,1} *(\\d+)")
    ]
    
    struct Book {
        var title: String
        var subtitle: String
        var series: String
        var position: Int
    }
    
    public func cleanup(book input: Book) -> Book? {
        struct Part: Constructable {
            var before = ""
            var part = ""
            var after = ""
        }

        let partPattern: NSRegularExpression = try! NSRegularExpression(pattern: "(.*?) *(Part \\d+) *(.*?)")

        var book = input
        if book.series.isEmpty { // only apply to books not already in a series
            for detector in detectors {
                if let detected = detector.detect(name: book.title, subtitle: book.subtitle) {
                    if book.subtitle == "" {
                        seriesDetectorChannel.log("detected with \(detector) from \"\(book.title)\"")
                    } else {
                        seriesDetectorChannel.log("detected with \(detector) from name: \"\(book.title)\" subtitle: \"\(book.subtitle)\"")
                    }
                    book.title = detected.name
                    book.subtitle = detected.subtitle
                    var series = detected.series
                    if (series != "" && detected.position != 0) {
                        let mapping = [\Part.before: 1, \Part.part: 2, \Part.after: 3]
                        if let match = partPattern.firstMatch(in: detected.series, capturing: mapping) {
                            book.title = detected.name + match.part
                            series = match.before + match.after
                        }
                        book.position = detected.position
                    }
                    book.series = series
                    seriesDetectorChannel.log("extracted <\(detected.name)> <\(detected.subtitle)> <\(series) \(detected.position)> from <\(input.title)> <\(input.subtitle)>")
                    return book
                }
            }
        }

        return nil
    }
}
