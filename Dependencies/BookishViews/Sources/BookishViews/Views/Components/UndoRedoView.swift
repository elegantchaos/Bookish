// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct UndoView: View {
    @EnvironmentObject var model: ModelController
    
    var body: some View {
        Button(action: model.handleUndo) {
            Image(systemName: "arrowshape.turn.up.backward")
        }
        .disabled(!model.canUndo)
    }
}

struct RedoView: View {
    @EnvironmentObject var model: ModelController
    
    var body: some View {
        Button(action: model.handleRedo) {
            Image(systemName: "arrowshape.turn.up.forward")
        }
        .disabled(!model.canRedo)
    }
}
