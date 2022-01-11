// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI


struct RemoveLinkMenu: View {
    let record: CDRecord
    let links: [CDRecord]
    
    @Environment(\.recordContainer) var container: CDRecord?
    
    init(_ record: CDRecord) {
        self.record = record
        self.links = record.sortedContainedBy
        
        print("Links for \(record.name)")
        print(links.map({ $0.name }))
    }
    
    var body: some View {
        if links.count > 0 {
            Menu("Remove Link") {
                ForEach(links) { record in
                    ForEach(record.sortedRoles(for: record), id: \.self) { role in
                        Button(action: { handleRemoveLink(of: record, as: role) }) {
                            RecordLabel(record: record, nameMode: .roleInline(role))
                        }
                    }
                }
            }
        }
    }
    
    func handleRemoveLink(of record: CDRecord, as role: String) {
        if let container = container {
            if container.roles(for: record).count == 1 {
                record.removeFromContents(container)
            }
            container.removeRole(role, of: record)
        }
    }

}
