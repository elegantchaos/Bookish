// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/02/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Localization

class Field: ObservableObject, Identifiable {
    
    enum Kind: String, CaseIterable {
        case string
        case number
        case date
        
        var label: String {
            rawValue.localized
        }
    }

    let id: UUID

    @Published var key: String
    @Published var kind: Kind
    
    init(key: String, kind: Kind) {
        self.id = UUID()
        self.key = key
        self.kind = kind
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
