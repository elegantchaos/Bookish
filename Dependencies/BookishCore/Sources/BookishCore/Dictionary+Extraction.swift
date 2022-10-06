// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Coercion
import Foundation
import ISBN
import SwiftUI
import AudioToolbox

// TODO: move these to BookRecord?

/// Generic utilities for extracting a value from a dictionary and cleaning it up.
/// If the extraction is successful, the key is removed from the source dictionary.

public extension Dictionary where Key == String, Value == Any {
    mutating func extractNonZeroDouble(forKey key: Key) -> Double? {
        
        guard let value = self[asDouble: key], value != 0 else { return nil }
        removeValue(forKey: key)
        return value
    }

    mutating func extractNonZeroInt(forKey key: Key) -> Int? {
        guard let value = self[asInt: key], value != 0 else { return nil }
        removeValue(forKey: key)
        return value
    }

    mutating func extractString(forKey key: Key) -> String? {
        guard let string = self[asString: key] else { return nil }
        removeValue(forKey: key)
        return string
    }

    mutating func extractDate(forKey key: Key) -> Date? {
        guard let date = self[asDate: key] else { return nil }
        removeValue(forKey: key)
        return date
    }

    mutating func extractStringList(forKey key: Key, separator: Character = "\n") -> [String] {
        guard let string = self[asString: key] else { return [] }
        let items = string.split(separator: separator)
        guard items.count > 0 else { return [] }

        removeValue(forKey: key)
        return items.map({ $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) })
    }
    
    mutating func extractISBN() -> String? {
        if let ean = self[asString: "ean"], ean.isISBN13 {
            removeValue(forKey: "ean")
            return ean
        } else if let value = self[asString: "isbn"], value.isISBN10 || value.isISBN13 {
            removeValue(forKey: "isbn")
            return value.isbn10to13
        }
        
        return nil
    }
}

/// Generic utilities for extracting a value from a source dictionary, cleaning it up,
/// and adding it this dictionary.
/// If the extraction is successful, the key is removed from the source dictionary.

public extension Dictionary where Key == String, Value == Any {

    mutating func extractNonZeroDouble(forKey key: Key, as asKey: Key? = nil, from source: inout Self) {
        self[asKey ?? key] = source.extractNonZeroDouble(forKey:key)
    }

    mutating func extractNonZeroInt(forKey key: Key, as asKey: Key? = nil, from source: inout Self) {
        self[asKey ?? key] = source.extractNonZeroInt(forKey: key)
    }

    mutating func extractString(forKey key: Key, as asKey: Key? = nil, from source: inout Self) {
        self[asKey ?? key] = source.extractString(forKey: key)
    }

    mutating func extractDate(forKey key: Key, as asKey: Key? = nil, from source: inout Self) {
        self[asKey ?? key] = source.extractDate(forKey: key)
    }

    mutating func extractStringList(forKey key: Key, separator: Character = "\n", as asKey: Key? = nil, from source: inout Self) {
        self[asKey ?? key] = source.extractStringList(forKey: key, separator: separator)
    }
    
    mutating func extractISBN(as asKey: Key, from source: inout Self) {
        self[asKey] = source.extractISBN()
    }
}

public extension Dictionary where Key == String, Value == Any {
    mutating func extractNonZeroDouble(forKey key: Key, as asKey: BookKey? = nil, from source: inout Self) {
        extractNonZeroDouble(forKey: key, as: asKey?.rawValue, from: &source)
    }

    mutating func extractNonZeroInt(forKey key: Key, as asKey: BookKey? = nil, from source: inout Self) {
        extractNonZeroDouble(forKey: key, as: asKey?.rawValue, from: &source)
    }

    mutating func extractString(forKey key: Key, as asKey: BookKey? = nil, from source: inout Self) {
        extractString(forKey: key, as: asKey?.rawValue, from: &source)
    }

    mutating func extractDate(forKey key: Key, as asKey: BookKey? = nil, from source: inout Self) {
        extractDate(forKey: key, as: asKey?.rawValue, from: &source)
    }

    mutating func extractStringList(forKey key: Key, separator: Character = "\n", as asKey: BookKey? = nil, from source: inout Self) {
        extractStringList(forKey: key, separator: separator, as: asKey?.rawValue, from: &source)
    }
    
    mutating func extractISBN(as asKey: BookKey = .isbn, from source: inout Self) {
        extractISBN(as: asKey.rawValue, from: &source)
    }

    mutating func extractNonZeroDouble(forKey key: BookKey) -> Double? {
        return extractNonZeroDouble(forKey: key.rawValue)
    }

    mutating func extractNonZeroInt(forKey key: BookKey) -> Int? {
        return extractNonZeroInt(forKey: key.rawValue)
    }

    mutating func extractString(forKey key: BookKey) -> String? {
        return extractString(forKey: key.rawValue)
    }

    mutating func extractDate(forKey key: BookKey) -> Date? {
        return extractDate(forKey: key.rawValue)
    }

    mutating func extractStringList(forKey key: BookKey, separator: Character = "\n") -> [String] {
        return extractStringList(forKey: key.rawValue, separator: separator)
    }
    
    func urls(forKey key: BookKey) -> [URL] {
        if let urls = self[key.rawValue] as? [URL] {
            return urls
        }
        
        if let strings = self[key.rawValue] as? [String] {
            return strings.compactMap { URL(string: $0) }
        }
        
        if let url = self[key.rawValue] as? URL {
            return [url]
        }
        
        guard let string = self[key.rawValue] as? String, let url = URL(string: string) else { return [] }
        return [url]
    }
    
    func strings(forKey key: BookKey) -> [String] {
        self[key.rawValue] as? [String] ?? []
    }
    
    subscript(_ key: BookKey) -> Any? {
        get { self[key.rawValue] }
        set(newValue) { self[key.rawValue] = newValue }
    }
    
    mutating func extractKeys(_ keys: [BookKey], from source: inout Self) {
        for key in keys {
            let raw = key.rawValue
            if let value = source[raw] {
                self[raw] = value
                source.removeValue(forKey: raw)
            }
        }
    }
}
