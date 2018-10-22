// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

public final class DetailSpec {
    public enum Kind {
        case text
        case date
    }

    public let binding: String
    public let label: String
    public let kind: Kind
    public let editable: Bool
    
    public init(binding: String, label: String? = nil, kind: Kind = .text, editable: Bool = true) {
        self.binding = binding
        self.label = label ?? binding
        self.kind = kind
        self.editable = editable
    }
    
    public class var standardDetails: [DetailSpec] {
        return [
            DetailSpec(binding: "notes", label: "Notes"),
            DetailSpec(binding: "format", label: "Format"),
            DetailSpec(binding: "isbn", label: "ISBN"),
            DetailSpec(binding: "published", label:  "Published", kind: .date),
            DetailSpec(binding: "added", label: "Added", kind: .date, editable: false),
            DetailSpec(binding: "modified", label: "Modified", kind: .date, editable: false)
        ]
    }
}
