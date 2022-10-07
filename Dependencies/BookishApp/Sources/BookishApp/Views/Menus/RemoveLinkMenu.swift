// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Logger
import SwiftUI

let linkMenuChannel = Channel("Link Menu")

struct RemoveLinkMenu: View {
    @Environment(\.recordViewer) var viewer: RecordViewer?
    @EnvironmentObject var model: ModelController
    
    var body: some View {
        
        if let record = viewer?.record {
            let links = record.linksTo()
            if links.count > 0 {
                Menu("Remove Link") {
                    ForEach(links) { linkRecord in
                        if let link = linkRecord.asLinkedRole(to: record) {
                            Button(action: { handleRemoveLink(linkRecord) }) {
                                RecordLabel(record: link.record, nameMode: .roleInline(link.role))
                            }
                        }
                    }
                }
            }
        }
    }
    
    func handleRemoveLink(_ link: CDRecord) {
        model.delete([link])
    }
}
