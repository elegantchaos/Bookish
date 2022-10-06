// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Returns a list of the top-level index views for a given list of record kinds.
struct KindIndexesListView: View {
    let kinds: [RecordKind]
    
    var body: some View {
        ForEach(kinds) { kind in
            NavigationLink(value: kind) {
                Label(kind.pluralLabel, systemImage: kind.indexIconName)
            }
        }

    }
}
