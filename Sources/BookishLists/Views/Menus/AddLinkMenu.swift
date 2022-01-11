// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct AddLinkMenu: View {
    @EnvironmentObject var model: ModelController

    var body: some View {
        Menu("Add Link") {
            AddLinkButton(kind: .book)
            ForEach(model.sortedRoles, id: \.self) { role in
                AddLinkButton(kind: .person, role: role)
            }
            AddLinkButton(kind: .publisher)
            AddLinkButton(kind: .series)
        }
    }
}
