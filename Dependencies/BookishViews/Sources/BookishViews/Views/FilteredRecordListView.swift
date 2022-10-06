// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Returns a list of records matching a given predicate (optionally sorted).
struct FilteredRecordListView: View {
    @Binding var filter: String
    @FetchRequest var records: FetchedResults<CDRecord>
    
    typealias DeleteHandler = (IndexSet?, FetchedResults<CDRecord>) -> ()
    
    let onDelete: DeleteHandler?
    
    init(predicate: NSPredicate, filter: Binding<String>, sort: [NSSortDescriptor]? = nil, onDelete: ((IndexSet?, FetchedResults<CDRecord>) -> ())? = nil) {
        let sort = sort ?? [NSSortDescriptor(key: "name", ascending: true)]
        self._records = .init(entity: CDRecord.entity(), sortDescriptors: sort, predicate: predicate)
        self._filter = filter
        self.onDelete = onDelete
    }
    
    var body: some View {
        ForEach(records) { record in
            if filter.isEmpty || record.name.contains(filter) {
                RecordLink(record)
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
