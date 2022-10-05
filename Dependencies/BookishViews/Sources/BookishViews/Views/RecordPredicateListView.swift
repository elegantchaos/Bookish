// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Returns a list of records matching a given predicate (optionally sorted).
struct RecordPredicateListView: View {
    @Binding var selection: String?
    @FetchRequest var lists: FetchedResults<CDRecord>
    
    init(predicate: NSPredicate, selection: Binding<String?>, sort: [NSSortDescriptor]? = nil) {
        let sort = sort ?? [NSSortDescriptor(key: "name", ascending: true)]
        self._lists = .init(entity: CDRecord.entity(), sortDescriptors: sort, predicate: predicate)
        self._selection = selection
    }
    
    var body: some View {
        ForEach(lists) { list in
            RecordLink(list, selection: $selection)
        }
    }
}
