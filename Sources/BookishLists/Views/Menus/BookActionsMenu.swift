// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI

protocol BookActionsDelegate {
    func handleDelete()
    func handlePickLink(kind: CDRecord.Kind, role: String)
    func handleAddLink(to: CDRecord)
}

struct BookActionsMenu: View {
    @EnvironmentObject var model: ModelController

    @ObservedObject var book: CDRecord
    let delegate: BookActionsDelegate
    
    var body: some View {
        Menu("Add Link") {
            ForEach(model.sortedRoles, id: \.self) { role in
                AddLinkButton(kind: .person, role: role, delegate: delegate)
            }
            AddLinkButton(kind: .publisher, delegate: delegate)
            AddLinkButton(kind: .series, delegate: delegate)
        }
        Button(action: delegate.handleDelete) { Label("Delete", systemImage: "trash") }
        EditButton()
    }
}
