// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct DeleteSelectionButton: View {
    @EnvironmentObject var model: ModelController
    
    let selection: Set<String>
    
    var body: some View {
        Button(action: handleDelete) {
            Label("Delete Selected Items", systemImage: "trash")
        }
    }
    
    func handleDelete() {
        model.delete(selection)
    }
}
