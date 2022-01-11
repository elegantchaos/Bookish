// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI


struct RemoveLinkMenu: View {
    @Environment(\.recordViewer) var viewer: RecordViewer?
    
    enum Mode {
        case link
        case item
    }
    
    let mode: Mode
    
    var body: some View {
        
        if let (links, label) = sortedLinks, let containingRecord = viewer?.container {
            Menu(label) {
                ForEach(links) { linkedRecord in
                    RoleItemsView(mode: mode, containingRecord: containingRecord, linkedRecord: linkedRecord)
                }
            }
        }
    }
    
    var sortedLinks: ([CDRecord], String)? {
        guard let container = viewer?.container else {
            return nil
        }
        
        let links: [CDRecord]
        let label: String
        let debug: String
        
        switch mode {
            case .link:
                links = container.sortedContainedBy
                label = "Remove Link"
                debug = "Links for \(container.name)"
                
            case .item:
                links = container.sortedContents
                label = "Remove Item"
                debug = "Contents of \(container.name)"
        }
        
        guard links.count > 0 else { return nil }
        
        print(debug)
        print(links.map({ $0.name }))
        return (links, label)
    }
}

private struct RoleItemsView: View {
    internal init(mode: RemoveLinkMenu.Mode, containingRecord: CDRecord, linkedRecord: CDRecord) {
        switch mode {
            case .link:
                self.containingRecord = containingRecord
                self.linkedRecord = linkedRecord
                self.labelRecord = linkedRecord

            case .item:
                self.containingRecord = linkedRecord
                self.linkedRecord = containingRecord
                self.labelRecord = linkedRecord
        }
    }
    
    let containingRecord: CDRecord
    let linkedRecord: CDRecord
    let labelRecord: CDRecord
    
    var body: some View {
        let roles = containingRecord.sortedRoles(for: linkedRecord)
        return ForEach(roles, id: \.self) { role in
            Button(action: { handleRemoveLink(of: linkedRecord, from: containingRecord, as: role) }) {
                RecordLabel(record: labelRecord, nameMode: .roleInline(role))
            }
        }
    }

    func handleRemoveLink(of record: CDRecord, from container: CDRecord, as role: String) {
        if container.roles(for: record).count == 1 {
            record.removeFromContents(container)
        }
        container.removeRole(role, of: record)
    }
    

}
