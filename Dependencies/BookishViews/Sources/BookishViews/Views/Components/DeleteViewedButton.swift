// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Button which deletes the record currently being viewed.
/// The `recordViewed` environment variable is used to work
/// out which record to delete, and also to dismiss the view,
/// since the thing it's showing no longer exists.

struct DeleteViewedButton: View {
    @EnvironmentObject var model: ModelController
    @Environment(\.recordViewer) var viewer: RecordViewer?
    
    var body: some View {
        Button(action: handleDelete) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    func handleDelete() {
        if let viewer {
            viewer.dismiss()
            model.delete([viewer.record])
        }
    }
}
