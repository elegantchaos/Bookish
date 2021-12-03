// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A dictionary-based book record.
/// The record is guaranteed to have three properties:
/// - id: a unique identifier
/// - title: the title of the book
/// - source: the origin of the record; this might be an importer, a lookup service, or a manual input by a user
///
/// All other properties are manual and stored in a dictionary.

public struct BookRecord: Identifiable {
    public let id: String
    public var title: String
    public var source: String
    public var properties: [String:Any]
    
    /// To be a valid record, the dictionary must at a minimum contain the id and title fields.
    /// If an explicit source is supplied, it takes precendence, otherwise if the record contains one we use that,
    /// otherwise we fall back on the default source.
    ///
    public init?(_ dictionary: [String:Any], id explicitID: String? = nil, source: String? = nil) {
        var properties = dictionary
        guard let id = explicitID ?? properties.extractString(forKey: .idKey), let title = properties.extractString(forKey: .titleKey) else { return nil }
        self.id = id
        self.title = title
        self.source = source ?? properties.extractString(forKey: .sourceKey) ?? Self.defaultSource
        self.properties = properties
    }

    public static let defaultSource = "com.elegantchaos.bookish.raw"
    
    public var imageURLS: [URL] {
        properties[.imageURLsKey] as? [URL] ?? []
    }
    
    public var authors: [String] {
        (properties[.authorsKey] as? [String]) ?? []
    }
    
    public var publishers: [String] {
        (properties[.publishersKey] as? [String]) ?? []
    }
}

extension BookRecord: Equatable {
    public static func == (lhs: BookRecord, rhs: BookRecord) -> Bool {
        (lhs.id == rhs.id) && (lhs.title == rhs.title) && (lhs.source == rhs.source) && (lhs.properties.keys == rhs.properties.keys) // TODO: do we need to compare property values?
    }
}
