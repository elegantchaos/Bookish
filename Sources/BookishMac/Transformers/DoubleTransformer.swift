// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 29/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

class DoubleTransformer: ValueTransformer {
    
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        if let number = value as? NSNumber {
            return number.stringValue
        } else if let number = value as? Double {
            return "\(number)"
        } else {
            return nil
        }
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let string = value as? NSString {
            return string.doubleValue
        } else {
            return nil
        }
    }
    
}
