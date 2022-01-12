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

extension NSDate: JSONRepresentable {
    var asJSONType: JSONType {
        return DateFormatter.localizedString(from: self as Date, dateStyle: .full, timeStyle: .full)
    }
}
