//
//  JSONRepresentable.swift
//  BookishLists
//
//  Created by Sam Deane on 12/01/2022.
//

import Foundation
import Accessibility

protocol JSONType {
    var asJSONType: JSONType { get }
}

protocol JSONRepresentable {
    var asJSONType: JSONType { get }
}

extension Int: JSONType {
    var asJSONType: JSONType { return self }
}

extension Double: JSONType {
    var asJSONType: JSONType { return self }
}

extension String: JSONType {
    var asJSONType: JSONType { return self }
}

extension CFString: JSONType {
    var asJSONType: JSONType { return self }
}

extension Date: JSONRepresentable {
    var asJSONType: JSONType {
        return DateFormatter.localizedString(from: self, dateStyle: .full, timeStyle: .full)
    }
}

extension NSDate: JSONRepresentable {
    var asJSONType: JSONType {
        return DateFormatter.localizedString(from: self as Date, dateStyle: .full, timeStyle: .full)
    }
}

typealias JSONDictionary = Dictionary<String, JSONType>

extension JSONDictionary: JSONType {
    var asJSONType: JSONType {
        return self
    }
}

typealias JSONArray = Array<JSONType>

extension JSONArray: JSONType {
    var asJSONType: JSONType {
        return self
    }
}

extension Array: JSONRepresentable where Element == Any {
    var asJSONType: JSONType {
        return self.map { (item: Any) -> JSONType in
            guard let rep = item as? JSONRepresentable else { fatalError("") }
            return rep.asJSONType
        }
    }
}

extension NSArray: JSONRepresentable {
    var asJSONType: JSONType {
        return self.map { (item: Any) -> JSONType in
            guard let rep = item as? JSONRepresentable else { fatalError("") }
            return rep.asJSONType
        }
    }
}

extension NSString: JSONRepresentable {
    var asJSONType: JSONType {
        return self as String
    }
}

//
//extension Dictionary: JSONType where Key == String, Value: JSONType {
//    var asJSONType: JSONType {
//        return self
//    }
//}

@objc protocol JSONRepresentableObject {
    var asJSONObject: Any { get }
}

extension NSDate: JSONRepresentableObject {
    var asJSONObject: Any {
        return DateFormatter.localizedString(from: self as Date, dateStyle: .full, timeStyle: .full)
    }
}

extension NSString: JSONRepresentableObject {
    var asJSONObject: Any {
        return self
    }
}

class ExtendedJSONSerialization: JSONSerialization {
    @objc override class func isValidJSONObject(_ obj: Any) -> Bool {
        if super.isValidJSONObject(obj) {
            return true
        }
        
        return obj is JSONRepresentable
    }
    
    @objc override class func writeJSONObject(_ obj: Any, to stream: OutputStream, options opt: JSONSerialization.WritingOptions = [], error: NSErrorPointer) -> Int {
        let converted = super.isValidJSONObject(obj) ? obj : convert(obj)
        return super.writeJSONObject(converted, to: stream, options: opt, error: error)
    }
    
    class func convert(_ obj: Any) -> Any {
        if let convertible = obj as? JSONRepresentableObject {
            return convertible.asJSONObject
        }

        return obj
    }
    
    class func convert(_ date: NSDate) -> Any {
        return DateFormatter.localizedString(from: date as Date, dateStyle: .full, timeStyle: .full)
    }
}
