// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI


struct RemoveItemMenu: View {
    @Environment(\.recordContainer) var container: RecordContainerView?
    
    var body: some View {
        let links = sortedContents
        if links.count > 0, let containingRecord = container?.container {
            Menu("Remove Item") {
                ForEach(links) { linkedRecord in
                    ForEach(linkedRecord.sortedRoles(for: containingRecord), id: \.self) { role in
                        Button(action: { handleRemove(record: linkedRecord, as: role) }) {
                            RecordLabel(record: linkedRecord)
                        }
                    }
                }
            }
        }
    }
    
    var sortedContents: [CDRecord] {
        guard let container = container?.container else {
            return []
        }

        let links = container.sortedContents
        print("Contents for \(container.name)")
        print(links.map({ $0.name }))
        return links
    }
    
    func handleRemove(record: CDRecord, as role: String) {
        if let container = container?.container {
            if record.roles(for: container).count == 1 {
                container.removeFromContents(record)
            }
            record.removeRole(role, of: container)
        }
    }
}
