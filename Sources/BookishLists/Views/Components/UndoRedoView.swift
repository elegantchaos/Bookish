// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct UndoView: View {
    @EnvironmentObject var model: Model
    
    var body: some View {
        let manager = model.stack.undoManager
        Button(action: model.handleUndo) {
            Image(systemName: "arrowshape.turn.up.backward")
        }
        .disabled(!manager.canUndo)
    }
}

struct RedoView: View {
    @EnvironmentObject var model: Model
    
    var body: some View {
        let manager = model.stack.undoManager
        Button(action: model.handleRedo) {
            Image(systemName: "arrowshape.turn.up.forward")
        }
        .disabled(!manager.canRedo)
    }
}
