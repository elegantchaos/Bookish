// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/11/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct RecordLink: View {
    let record: CDRecord
    let list: CDRecord?
    let selection: Binding<String?>
    
    init(_ record: CDRecord, in list: CDRecord? = nil, selection: Binding<String?>) {
        self.record = record
        self.list = list
        self.selection = selection
    }
    var body: some View {
        NavigationLink(tag: record.id, selection: selection) {
            if record.isBook {
                BookView(book: record, fields: list?.fields ?? FieldList())
            } else {
                ListIndexView(list: record)
            }
        } label: {
            RecordLabel(record: record)
        }
    }
}