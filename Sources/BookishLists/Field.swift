// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/02/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCore
import Foundation
import Localization

class Field: ObservableObject, Identifiable {
    
    enum Kind: String, CaseIterable {
        case string
        case paragraph
        case number
        case date
        
        var label: String {
            rawValue.localized
        }
        
        var defaultIcon: String {
            switch self {
                case .string: return "tag"
                case .paragraph: return "note.text"
                case .number: return "tag"
                case .date: return "calendar"
            }
        }
    }

    enum Layout {
        case inline
        case below
        case belowNoLabel
    }


    let id: UUID
    let label: String
    let icon: String
    let layout: Layout
    
    @Published var key: String
    @Published var kind: Kind

    convenience init(_ key: BookKey, kind: Kind, label: String? = nil, icon: String? = nil, layout: Layout = .inline) {
        self.init(key.rawValue, kind: kind, label: label, icon: icon, layout: layout)
    }
    
    init(_ key: String, kind: Kind, label: String? = nil, icon: String? = nil, layout: Layout = .inline) {
        self.id = UUID()
        self.key = key
        self.kind = kind
        self.label = label ?? key
        self.icon = icon ?? kind.defaultIcon
        self.layout = layout
    }
    
    var kindString: String {
        get { kind.rawValue }
        set { kind = Kind(rawValue: newValue) ?? .string }
    }
}

extension Field: Equatable {
    static func == (lhs: Field, rhs: Field) -> Bool {
        lhs.id == rhs.id
    }
}

extension Field: Hashable {
    func hash(into hasher: inout Hasher) {
        id.hash(into: &hasher)
    }
}
