// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 25/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Expressions
import Foundation
import Logger

let seriesDetectorChannel = Logger("com.elegantchaos.bookish.model.SeriesDetector")

class SeriesDetector {
    static let bookPattern = "(Number |Book |Bk\\. |Bk\\.|Bk |No\\. |No\\.|No |)"
    
    struct Result {
        let name: String
        let subtitle: String
        let series: String
        let position: Int
        
    }

    internal struct Captured: Constructable {
        var name = ""
        var subtitle = ""
        var series = ""
        var rest = ""
        var extra = ""
        var position = 0
    }
    
    
    func detect(name: String, subtitle: String) -> Result? {
        return nil
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
    // eg: "Effendi: The Second Arabesk (Arabesk S.)"
    let pattern = try! NSRegularExpression(pattern: "(.*) \\((.*) S[.]{0,1}\\)")
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let match = pattern.firstMatch(in: name, capturing: [\Captured.name: 1, \Captured.series: 2]) {
            if !match.series.isEmpty && !name.isEmpty {
                let matchedSubtitle = subtitle.contains(match.series) ? "" : subtitle
                return Result(name: match.name, subtitle: matchedSubtitle, series: match.series, position: 0)
            }
        }
        
        return nil
    }
}

class SeriesBracketsBookDetector: SeriesDetector {
    // eg: name: "Carpe Jugulum (Discworld Novel)" subtitle: "Discworld Novel"
    let pattern = try! NSRegularExpression(pattern: "(.*) \\((.*)\\)$")
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let match = pattern.firstMatch(in: name, capturing: [\Captured.name: 1, \Captured.series: 2]) {
            if let series = matchWithArticles(subtitle, match.series) {
                return Result(name: match.name, subtitle: "", series: series, position: 0)
            }
        }
        return nil
    }
}

class TitleInSeriesDetector: SeriesDetector {
    // eg: "The Fuller Memorandum: Book 3 in The Laundry Files"
    let pattern = try! NSRegularExpression(pattern: "(.*?)[:, ]+\(SeriesDetector.bookPattern)(\\d+) (in|of) (.*?)$")
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let match = pattern.firstMatch(in: name, capturing: [\Captured.name: 1, \Captured.series: 5, \Captured.position: 3]) {
            return Result(name: match.name, subtitle: subtitle, series: match.series, position: match.position)
        }
        return nil
    }
}

class SeriesBracketsBookNumberDetector: SeriesDetector {
    // eg: "The Better Part of Valour: A Confederation Novel (Valour Confederation Book 2)"
    let pattern = try! NSRegularExpression(pattern: "(.*) \\(((.*?)[:, ]+\(SeriesDetector.bookPattern)(\\d+)(.*?))\\)$")
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let match = pattern.firstMatch(in: name, capturing: [\Captured.name: 1, \Captured.series: 3, \Captured.position: 5, \Captured.rest: 6, \Captured.extra: 2]) {
            let combinedName = match.name + match.rest
            if subtitle == match.extra {
                return Result(name: combinedName, subtitle: "", series: match.series, position: match.position)
            } else if let series = matchWithArticles(subtitle, match.extra) {
                return Result(name: combinedName, subtitle: "", series: series, position: match.position)
            }
            return Result(name: combinedName, subtitle: subtitle, series: match.series, position: match.position)
        }
        return nil
    }
}

class SeriesNameBookDetector: SeriesDetector {
    // eg: "The Amtrak Wars: Cloud Warrior Bk. 1"
    let pattern = try! NSRegularExpression(pattern: "(.*?)\\:+ (.*?)\\:{0,1} \(SeriesDetector.bookPattern)(\\d+)(.*)")
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let match = pattern.firstMatch(in: name, capturing: [\Captured.series: 1, \Captured.name: 2, \Captured.position: 4, \Captured.rest: 5]) {
            if !match.series.isEmpty && !name.isEmpty {
                let matchedSubtitle = subtitle.contains(match.series) ? "" : subtitle
                return Result(name: match.name + match.rest, subtitle: matchedSubtitle, series: match.series, position: match.position)
            }
        }
        
        return nil
    }
}

class NameSeriesBookBracketsDetector: SeriesDetector {
    // eg: "The Name of the Wind: The Kingkiller Chronicle: Book 1 (Kingkiller Chonicles)"
    let pattern = try! NSRegularExpression(pattern: "(.*?)\\:+ (.*?)\\:{0,1} \(SeriesDetector.bookPattern)(\\d+) \\((.*)\\)")
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let match = pattern.firstMatch(in: name, capturing: [\Captured.series: 2, \Captured.name: 1, \Captured.position: 4, \Captured.rest: 5]) {
            if !match.series.isEmpty && !name.isEmpty {
                let matchedSubtitle = subtitle.contains(match.series) ? "" : subtitle
                return Result(name: match.name, subtitle: matchedSubtitle, series: match.series, position: match.position)
            }
        }
        
        return nil
    }
}

class NameBookSeriesBracketsSDetector: SeriesDetector {
    // eg: "Name Book 2 (Series S.)"
    let pattern = try! NSRegularExpression(pattern: "(.*?)\\:{0,1} \(SeriesDetector.bookPattern)(\\d+) \\((.*) S.\\)")
    
    override func detect(name: String, subtitle: String) -> Result? {
        if let match = pattern.firstMatch(in: name, capturing: [\Captured.series: 4, \Captured.name: 1, \Captured.position: 3]) {
            if !match.series.isEmpty && !name.isEmpty {
                let matchedSubtitle = subtitle.contains(match.series) ? "" : subtitle
                return Result(name: match.name, subtitle: matchedSubtitle, series: match.series, position: match.position)
            }
        }
        
        return nil
    }
}

class SubtitleBookDetector: SeriesDetector {
    // eg: "The Amber Citadel" subtitle: "Jewelfire Trilogy 1"
    // eg: name: "Ancillary Justice" subtitle: "(Imperial Radch Book 1)"
    var pattern: NSRegularExpression { return try! NSRegularExpression(pattern: "\\({0,1}(.*?)[:, ]+\(SeriesDetector.bookPattern)(\\d+)(.*?)\\){0,1}") }

    override func detect(name: String, subtitle: String) -> Result? {
        let mapping = [\Captured.series: 1, \Captured.position: 3, \Captured.rest: 4]
        if let match = pattern.firstMatch(in: subtitle, capturing: mapping) {
            if !match.series.isEmpty {
                let series = match.series + match.rest
                return Result(name: name, subtitle: "", series: series, position: match.position)
            }
        }
        
        return nil
    }
}
