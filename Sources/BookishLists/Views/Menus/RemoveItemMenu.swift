// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI


struct RemoveItemMenu: View {
    let record: CDRecord
    let links: [CDRecord]
    
    @Environment(\.recordContainer) var container: CDRecord?
    
    init(_ record: CDRecord) {
        self.record = record
        self.links = record.sortedContents
        
        print("Contents for \(record.name)")
        print(links.map({ $0.name }))
    }
    
    var body: some View {
        if links.count > 0 {
            Menu("Remove Item") {
                ForEach(links) { record in
                    ForEach(record.sortedRoles(for: record), id: \.self) { role in
                        Button(action: { handleRemove(record: record, as: role) }) {
                            RecordLabel(record: record)
                        }
                    }
                }
            }
        }
    }
    
    func handleRemove(record: CDRecord, as role: String) {
        if let container = container {
            if record.roles(for: container).count == 1 {
                container.removeFromContents(record)
            }
            record.removeRole(role, of: container)
        }
    }
}
