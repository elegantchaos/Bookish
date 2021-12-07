// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct UndoRedoView: View {
    @EnvironmentObject var model: Model
    
    var body: some View {
        let manager = model.stack.undoManager
        if manager.canUndo {
            Button("Undo", action: model.handleUndo)
        }
        
        if manager.canRedo {
            Button("Redo", action: model.handleRedo)
        }
    }
}
