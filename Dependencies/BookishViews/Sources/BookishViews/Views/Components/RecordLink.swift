// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct RecordLink: View {
    @EnvironmentObject var model: ModelController
    @ObservedObject var record: CDRecord
    let list: CDRecord?
    @Binding var selection: String?
    let nameMode: RecordLabel.NameMode
    
    init(_ record: CDRecord, nameMode: RecordLabel.NameMode = .normal, in list: CDRecord? = nil, selection: Binding<String?>) {
        self.record = record
        self.list = list
        self._selection = selection
        self.nameMode = nameMode
    }

    var body: some View {
        NavigationLink(value: record) {
            RecordLabel(record: record, nameMode: nameMode)
        }
    }
}
