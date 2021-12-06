// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
//
///// Generic utilities for extracting a key from one dictionary, reformatting it,
///// and adding it to another.
///// If the extraction is successful, the original key is removed from the source dictionary.
//
//extension Dictionary where Key == String, Value == Any {
//    mutating func extractNonZeroDouble(forKey key: Key, as asKey: Key? = nil, from source: inout Self) {
//        if let value = self[key] as? Double, value != 0 {
//            self[asKey ?? key] = value
//        }
//        source.removeValue(forKey: key)
//    }
//
//    mutating func extractNonZeroInt(forKey key: Key, as asKey: Key? = nil, from source: inout Self) {
//        if let value = self[key] as? Int, value != 0 {
//            self[asKey ?? key] = value
//        }
//        source.removeValue(forKey: key)
//    }
//
//    mutating func extractString(forKey key: Key, as asKey: Key? = nil, from source: inout Self) {
//        if let string = source[asString: key] {
//            source.removeValue(forKey: key)
//            self[asKey ?? key] = string
//        }
//    }
//
//    mutating func extractDate(forKey key: Key, as asKey: Key? = nil, from source: inout Self) {
//        if let date = source[asDate: key] {
//            source.removeValue(forKey: key)
//            self[asKey ?? key] = date
//        }
//    }
//
//    mutating func extractStringList(forKey key: Key, separator: Character = "\n", as asKey: Key? = nil, from source: inout Self) {
//        if let string = source[asString: key] {
//            let items = string.split(separator: separator)
//            if items.count > 0 {
//                source.removeValue(forKey: key)
//                let trimSet = CharacterSet.whitespacesAndNewlines
//                self[asKey ?? key] = items.map({ $0.trimmingCharacters(in: trimSet) })
//            }
//        }
//    }
//
//    mutating func extractISBN(as asKey: BookKey = .isbn, from source: inout Self) {
//        // NB we leave the original ean/isbn keys in the source so they get stored unmodified
//        if let ean = source[asString: "ean"], ean.isISBN13 {
//            self[asKey.rawValue] = ean
//        } else if let value = source[asString: "isbn"] {
//            let trimmed = value.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
//            self[.isbnKey] = trimmed.isbn10to13
//        }
//    }
//}

