// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct AddLinkButton: View {
    let kind: CDRecord.Kind
    let delegate: BookActionsDelegate

    var body: some View {
        Button(action: { delegate.handlePickLink(kind: kind) }) { Label(kind.roleLabel, systemImage: kind.iconName) }
    }
}
