// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 30/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

class DateTransformer: ValueTransformer {
    let formatter: DateFormatter
    let detector: NSDataDetector?
    
    init(dateStyle: DateFormatter.Style = .medium,  timeStyle: DateFormatter.Style = .none) {
        let f = DateFormatter()
        f.dateStyle = dateStyle
        f.timeStyle = timeStyle
        f.locale = Locale.current
        f.doesRelativeDateFormatting = true
        self.formatter = f
        self.detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    }
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        guard let date = value as? Date else {
            return value
        }
        
        return formatter.string(from: date)
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        guard let string = value as? String else {
            return value
        }
        
        if let date = formatter.date(from: string) {
            return date
        }
        
        if let matches = detector?.matches(in: string, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: string.count)) {
            if let date = matches.first?.date {
                return date
            }
        }
        
        return value
    }
    
}
