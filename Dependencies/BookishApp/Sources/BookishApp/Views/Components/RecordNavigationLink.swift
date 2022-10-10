// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct RecordNavigationLink: View {
    @ObservedObject var record: CDRecord
    
    let link: RecordLink
    let nameMode: RecordLabel.NameMode
    
    init(_ record: CDRecord, nameMode: RecordLabel.NameMode = .normal, in source: CDRecord? = nil) {
        self.record = record
        self.link = RecordLink(record: record, source: source)
        self.nameMode = nameMode
    }

    var body: some View {
        NavigationLink(value: link) {
            RecordLabel(record: record, nameMode: nameMode)
        }
    }
}
