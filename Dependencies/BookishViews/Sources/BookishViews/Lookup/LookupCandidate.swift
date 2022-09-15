// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCore
import Foundation
import BookishCore

class LookupCandidate: ObservableObject, Identifiable {
    let id = UUID()
    let service: LookupService
    let title: String
    let authors: [String]
    let publisher: String
    let image: URL?
    let book: BookRecord
    @Published var imported = false
    
    init(service: LookupService, record: BookRecord) {
        self.title = record.title
        self.authors = record.strings(forKey:.authors)
        self.publisher = record.strings(forKey: .publishers).first ?? ""
        self.service = service
        self.book = record
        self.image = record.urls(forKey: .imageURLs).first
    }

    var summary: String {
        return summaryItems.joined(separator: ", ")
    }
    
    var summaryItems: [String] {
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
