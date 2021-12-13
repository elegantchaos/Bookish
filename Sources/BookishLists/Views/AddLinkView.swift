// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI


protocol AddLinkDelegate {
    func handleAddLink(to: CDRecord)
}

struct AddLinkView<P: FetchProvider>: View {
    @FetchRequest(fetchRequest: P.request()) var records: FetchedResults<CDRecord>

    @State var filter: String = ""

    let delegate: AddLinkDelegate

    init(_ provider: P.Type, delegate: AddLinkDelegate) {
        self.delegate = delegate
    }
    
    var body: some View {
        VStack {
            Text("Add \(P.kind.roleLabel) Link")

            TextField("filter", text: $filter)
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
