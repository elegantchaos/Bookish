// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CoreData
import SwiftUI

protocol BookActionsDelegate {
    func handleDelete()
//    func handlePickLink(kind: CDRecord.Kind, role: String)
    func handleAddLink(to: CDRecord)
}

extension BookActionsDelegate {
    func handleDelete() { }
    func handlePickLink(kind: CDRecord.Kind, role: String) { }
    func handleAddLink(to: CDRecord) { }
}

struct BookActionsMenu: View {
    @EnvironmentObject var model: ModelController

    @ObservedObject var book: CDRecord
    let delegate: BookActionsDelegate
    
    var body: some View {
        AddLinkMenu()
        RemoveLinkMenu(book)
        
        Button(action: delegate.handleDelete) { Label("Delete", systemImage: "trash") }
        EditButton()
    }
}
