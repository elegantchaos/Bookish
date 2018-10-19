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
            DetailSpec(binding: "notes"),
            DetailSpec(binding: "format"),
            DetailSpec(binding: "isbn"),
            DetailSpec(binding: "published", kind: .date),
            DetailSpec(binding: "added", kind: .date, editable: false),
            DetailSpec(binding: "modified", kind: .date, editable: false)
        ]
    }
}
