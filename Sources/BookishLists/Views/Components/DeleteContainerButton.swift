// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct DeleteContainerButton: View {
    @EnvironmentObject var model: ModelController
    @Environment(\.recordContainer) var container: RecordContainerView?
    
    var body: some View {
        Button(action: handleDelete) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    func handleDelete() {
        if let view = container {
            view.dismiss()
            model.delete(view.container)
        }
    }
}
