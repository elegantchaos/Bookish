// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 30/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa

class DateTransformer: ValueTransformer {
    static let name = NSValueTransformerName(rawValue: "DateToString")
    
    let formatter: DateFormatter
    
    override init() {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        f.locale = Locale.current
        f.doesRelativeDateFormatting = true
        self.formatter = f
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
        
        
        guard let date = formatter.date(from: string) else {
            return value
        }
        
        return date
    }
    
}
