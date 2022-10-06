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
            let records = record.linksTo()
            if records.count > 0 {
                Menu("Remove Link") {
                    ForEach(records, id: \.self) { record in
                        if let link = record.asLink {
                            Button(action: { handleRemoveLink(record) }) {
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
