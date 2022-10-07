// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/10/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI
import SheetController
import BookishImporterSamples

// TODO: can this be merged with KindIndexActionsMenu, ListActionsMenu?

struct RoleActionsMenu: View {
    @EnvironmentObject var model: ModelController
    @Environment(\.editMode) var editMode

    @ObservedObject var role: CDRecord
    let records: [CDRecord]
    @Binding var selection: Set<String>

    var body: some View {
        let isEditing = editMode?.wrappedValue == .active
        if isEditing {
            Button(action: handleStopEditing) {
                Label("Finish Editing", systemImage: "pencil.slash")
            }
        } else {
            Button(action: handleStartEditing) {
                Label("Select Items", systemImage: "pencil")
            }
        }
        
        Button(action: handleSelectAll) {
            Label("Select All", systemImage: "checkmark.circle")
        }
        .disabled(selection.count == records.count)
        
        Button(action: handleClearSelection) {
            Label("Clear Selection", systemImage: "x.circle")
        }
        .disabled(selection.count == 0)

        MergeSelectionButton(selection: selection)
            .disabled(selection.count < 2)
        
        DeleteSelectionButton(selection: selection)
            .disabled(!deletableItemsSelected)
        
        ExportButton()
    }
    

    var deletableItemsSelected: Bool {
        let records = model.recordsWithIDs(selection)
        return records.contains { $0.canDelete }
    }
    
    func handleStopEditing() {
        editMode?.wrappedValue = .inactive
    }

    func handleStartEditing() {
        editMode?.wrappedValue = .active
    }

    func handleSelectAll() {
        let allIDs = records.map { $0.id }
        selection = Set(allIDs)
        editMode?.wrappedValue = .active
    }
    
    func handleClearSelection() {
        selection = []
    }
}
