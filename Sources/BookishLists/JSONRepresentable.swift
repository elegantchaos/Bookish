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

extension JSONType {
    var asJSONType: JSONType {
        return self
    }
}

protocol JSONRepresentable {
    var asJSONType: JSONType { get }
}

typealias JSONDictionary = Dictionary<String, JSONType>
typealias JSONArray = Array<JSONType>

extension Int: JSONType {
}

extension Double: JSONType {
}

extension String: JSONType {
}

extension JSONDictionary: JSONType {
}


extension JSONArray: JSONType {
}

// MARK: Swift Foundation Types

extension Date: JSONRepresentable {
    var asJSONType: JSONType {
        return DateFormatter.localizedString(from: self, dateStyle: .full, timeStyle: .full)
    }
}

//
//extension Array: JSONRepresentable where Element == Any {
//    var asJSONType: JSONType {
//        return self.map { (item: Any) -> JSONType in
//            guard let rep = item as? JSONRepresentable else { fatalError("") }
//            return rep.asJSONType
//        }
//    }
//}

// MARK: Core Foundation Types

extension CFString: JSONRepresentable {
    var asJSONType: JSONType { return self as String }
}

// MARK: ObjC Foundation Types

extension NSArray: JSONRepresentable {
    var asJSONType: JSONType {
        return self.map { (item: Any) -> JSONType in
            return (item as! JSONRepresentable).asJSONType
        }
    }
}

extension NSDictionary: JSONRepresentable {
    var asJSONType: JSONType {
        var mapped = JSONDictionary()
        for (key, value) in self {
            mapped[key as! String] = (value as! JSONRepresentable).asJSONType
        }
        return mapped
    }
}

extension NSString: JSONRepresentable {
    var asJSONType: JSONType {
        return self as String
    }
}

extension NSDate: JSONRepresentable {
    var asJSONType: JSONType {
        return DateFormatter.localizedString(from: self as Date, dateStyle: .full, timeStyle: .full)
    }
}
