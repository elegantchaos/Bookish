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
    func handleRemoveLink(to: CDRecord, role: String)
}

struct BookActionsMenu: View {
    @EnvironmentObject var model: ModelController

    @ObservedObject var book: CDRecord
    let delegate: BookActionsDelegate
    
    var body: some View {
        let links = existingLinks
        
        Menu("Add Link") {
            ForEach(model.sortedRoles, id: \.self) { role in
                AddLinkButton(kind: .person, role: role, delegate: delegate)
            }
            AddLinkButton(kind: .publisher, delegate: delegate)
            AddLinkButton(kind: .series, delegate: delegate)
        }
        
        if links.count > 0 {
            Menu("Remove Link") {
                ForEach(links) { record in
                    ForEach(book.sortedRoles(for: record), id: \.self) { role in
                        Button(action: { delegate.handleRemoveLink(to: record, role: role) }) {
                            RecordLabel(record: record, nameMode: .roleInline(role))
                        }
                    }
                }
            }
        }
        
        Button(action: delegate.handleDelete) { Label("Delete", systemImage: "trash") }
        EditButton()
    }
    
    var existingLinks: [CDRecord] {
        let links = book.sortedContainedBy
        print("Links for \(book.name)")
        print(links.map({ $0.name }))
        return links
    }
}
