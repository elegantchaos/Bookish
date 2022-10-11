// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI


protocol AddLinkDelegate {
    func handleAddLink(to: CDRecord)
}

struct AddLinkView: View {
    @FetchRequest var records: FetchedResults<CDRecord>

    @State var filter: String = ""

    let kind: RecordKind
    let delegate: AddLinkDelegate

    init(kind: RecordKind, delegate: AddLinkDelegate) {
        self._records = .init(entity: CDRecord.entity(), sortDescriptors: .defaultSort, predicate: .init(kind: kind))
        self.delegate = delegate
        self.kind = kind
    }
    
    var body: some View {
        VStack {
            TextField("\(kind.roleLabel) to link to:", text: $filter)
                .padding(.horizontal)

            List {
                ForEach(records) { record in
                    if filter.isEmpty || record.name.contains(filter) {
                        Button(action: { delegate.handleAddLink(to: record) }) {
                            RecordLabel(record: record)
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .padding(.vertical)
    }
}