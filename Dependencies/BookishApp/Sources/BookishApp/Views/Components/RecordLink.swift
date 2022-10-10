// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct RecordLink: View {
    @ObservedObject var record: CDRecord
    
    let link: RecordPath
    let nameMode: RecordLabel.NameMode
    
    init(_ record: CDRecord, nameMode: RecordLabel.NameMode = .normal, in context: CDRecord? = nil) {
        self.record = record
        self.link = RecordPath(record: record, context: context)
        self.nameMode = nameMode
    }

    var body: some View {
        NavigationLink(value: link) {
            RecordLabel(record: record, nameMode: nameMode)
        }
    }
}
