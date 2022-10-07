// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct MergeSelectionButton: View {
    @EnvironmentObject var model: ModelController
    
    let selection: Set<String>
    
    var body: some View {
        Button(action: handleMerge) {
            Label("Merge Selected Items", systemImage: "arrow.triangle.merge")
        }
    }
    
    func handleMerge() {
        let records = model.recordsWithIDs(selection)
        model.merge(records)
    }
}
