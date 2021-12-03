// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCore
import Foundation
import BookishCore

public class LookupCandidate: Identifiable {
    public let id = UUID()
    public let service: LookupService
    public let title: String
    public let authors: [String]
    public let publisher: String
    public let image: URL?
    public let book: BookRecord
    public var imported = false
    
    public init(service: LookupService, record: BookRecord) {
        self.title = record.title
        self.authors = record.authors
        self.publisher = record.publishers.first ?? ""
        self.service = service
        self.book = record
        self.image = record.imageURLS.first
    }

    public var summary: String {
        return summaryItems.joined(separator: ", ")
    }
    
    public var summaryItems: [String] {
        var items: [String] = []
        items.append(contentsOf: authors)
        items.append(publisher)
        return items
    }
}

extension LookupCandidate: CustomStringConvertible {
    public var description: String {
        get {
            return "<Candidate: \(title) \(authors) \(publisher)>"
        }
    }
}
