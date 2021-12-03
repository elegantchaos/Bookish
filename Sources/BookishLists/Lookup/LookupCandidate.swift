// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 27/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

//import Datastore
import Foundation

public class LookupCandidate: Identifiable {
    public struct Persisted: Codable {
        let name: String
        let data: String
    }
    
    public let id = UUID()
    public let service: LookupService
    public let title: String
    public let authors: [String]
    public let publisher: String
    public let date: Date?
    public let image: String?
    
    public init(service: LookupService, title: String? = nil, authors: [String]? = [], publisher: String? = nil, date: Date? = nil, image: String? = nil) {
        self.title = title ?? ""
        self.authors = authors ?? []
        self.publisher = publisher ?? ""
        self.date = date
        self.service = service
        self.image = image
    }
    
    public var persisted: Persisted {
        return Persisted(name: service.name, data: persistedData)
    }
    
    internal var persistedData: String {
        return ""
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
    
    public var action: String {
        return ""
    }
    
    public var existingBook: Any? {
        return nil
    }
}

extension LookupCandidate: CustomStringConvertible {
    public var description: String {
        get {
            return "<Candidate: \(title) \(authors) \(publisher)>"
        }
    }
}
