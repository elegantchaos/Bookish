// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI


struct RemoveLinkMenu: View {
    @Environment(\.recordContainer) var container: RecordContainerView?
    
    enum Mode {
        case link
        case item
    }
    
    let mode: Mode
    
    var body: some View {
        let links = sortedLinks
        if links.count > 0, let containingRecord = container?.container {
            Menu(mode == .link ? "Remove Link" : "Remove Item") {
                ForEach(links) { linkedRecord in
                    RoleItemsView(mode: mode, containingRecord: containingRecord, linkedRecord: linkedRecord)
                }
            }
        }
    }
    
    var sortedLinks: [CDRecord] {
        guard let container = container?.container else {
            return []
        }
        
        let links: [CDRecord]
        
        switch mode {
            case .link:
                links = container.sortedContainedBy
                print("Links for \(container.name)")
                
            case .item:
                links = container.sortedContents
                print("Contents for \(container.name)")
        }
        
        print(links.map({ $0.name }))
        return links
    }
}

struct RoleItemsView: View {
    let mode: RemoveLinkMenu.Mode
    let containingRecord: CDRecord
    let linkedRecord: CDRecord
    
    var body: some View {
        let roles: [String]
        let action: (CDRecord, String) -> ()
        
        switch mode {
            case .link:
                roles = containingRecord.sortedRoles(for: linkedRecord)
                action = { linkedRecord, role in handleRemoveLink(of: linkedRecord, from: containingRecord, as: role) }
                
            case .item:
                roles = linkedRecord.sortedRoles(for: containingRecord)
                action = { linkedRecord, role in handleRemoveLink(of: containingRecord, from: linkedRecord, as: role) }
        }
        
        return ForEach(roles, id: \.self) { role in
            Button(action: { action(linkedRecord, role) }) {
                RecordLabel(record: linkedRecord, nameMode: .roleInline(role))
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
