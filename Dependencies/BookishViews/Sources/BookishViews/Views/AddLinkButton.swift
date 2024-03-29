// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct AddLinkButton: View {
    @EnvironmentObject var linkController: LinkController
    
    let kind: CDRecord.Kind
    let role: String
    let label: String
    
    init(kind: CDRecord.Kind, role: String? = nil) {
        self.kind = kind
        self.role = role ?? kind.defaultRole
        self.label = NSLocalizedString("role.\(self.role)", comment: "")
    }
    
    var body: some View {
        Button(action: handlePickLink) { Label(label, systemImage: kind.iconName) }
    }
    
    func handlePickLink() {
        linkController.session = .init(kind: kind, role: role)
    }
}
