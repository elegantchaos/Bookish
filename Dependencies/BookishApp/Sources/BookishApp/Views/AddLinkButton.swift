// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct AddLinkButton: View {
    @EnvironmentObject var linkController: LinkController
    
    let kind: RecordKind
    let role: CDRecord?
    let label: String
    
    init(kind: RecordKind, role: CDRecord? = nil) {
        self.kind = kind
        self.role = role
        self.label = role?.name ?? kind.roleLabel
    }
    
    var body: some View {
        Button(action: handlePickLink) { Label(label, systemImage: kind.iconName) }
    }
    
    func handlePickLink() {
        linkController.session = .init(kind: kind, role: role)
    }
}