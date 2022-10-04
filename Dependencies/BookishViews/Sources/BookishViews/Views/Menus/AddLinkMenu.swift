// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct AddLinkMenu: View {
    @EnvironmentObject var model: ModelController

    enum Mode {
        case link
        case item
    }
    
    let mode: Mode

    var body: some View {
        Menu(mode == .link ? "Add Link" : "Add Item") {
            AddLinkButton(kind: .book)
            ForEach(model.sortedRoles, id: \CDRecord.id) { role in
                AddLinkButton(kind: .person, role: role)
            }
            AddLinkButton(kind: .publisher)
            AddLinkButton(kind: .series)
        }
    }
}
