// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct AddLinkButton: View {
    let kind: CDRecord.Kind
    let delegate: BookActionsDelegate
    let role: String

    init(kind: CDRecord.Kind, role: String? = nil, delegate: BookActionsDelegate) {
        self.kind = kind
        self.delegate = delegate
        self.role = role ?? kind.roleLabel
    }
    
    var body: some View {
        Button(action: { delegate.handlePickLink(kind: kind, role: role) }) { Label(role, systemImage: kind.iconName) }
    }
}
