// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Returns a list of records matching a given predicate (optionally sorted).
struct FilteredRecordListView: View {
    typealias DeleteHandler = (IndexSet?, FetchedResults<CDRecord>) -> ()

    let records: FetchedResults<CDRecord>
    @Binding var filter: String
    let onDelete: DeleteHandler?

    init(records: FetchedResults<CDRecord>, filter: Binding<String>, onDelete: DeleteHandler? = nil) {
        self.records = records
        self._filter = filter
        self.onDelete = onDelete
    }
    
    var body: some View {
        ForEach(records) { record in
            if filter.isEmpty || record.name.contains(filter) {
                RecordNavigationLink(record)
            }
        }
        .onDelete(perform: deleteAdaptor)
    }
    
    /// If we have an onDelete handler, return a block that calls it.
    /// Otherwise, return nil so that delete handling isn't set up by SwiftUI
    var deleteAdaptor: ((IndexSet) -> Void)? {
        guard let onDelete else { return nil }
        
        return { items in
            onDelete(items, records)
        }
    }
}
