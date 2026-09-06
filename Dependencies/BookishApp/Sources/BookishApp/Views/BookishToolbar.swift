// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import CommandsUI
import SwiftUI

/// Provides the browser actions and layout picker in the main toolbar.
struct BookishToolbar: ToolbarContent {
  /// The datastore coordinator backing toolbar actions and selection.
  let harness: BookishHarness

  /// The toolbar items for import, export, record actions, and layouts.
  var body: some ToolbarContent {
    ToolbarItem {
      harness.button(ImportInterchangeCommand())
        .labelStyle(.iconOnly)
    }

    ToolbarItem {
      harness.button(ExportInterchangeCommand())
        .labelStyle(.iconOnly)
    }

    harness.toolbarItem(MarkReadingCommand())
    harness.toolbarItem(MarkFinishedCommand())
    harness.toolbarItem(SimulateRemoteMutationCommand())

    ToolbarItem {
      @Bindable var harness = harness
      Picker("Layout", selection: $harness.selectedLayoutID) {
        Text("Default").tag(Optional<BookishRecordID>.none)
        ForEach(harness.compatibleLayoutIDs, id: \.self) { id in
          BookishLayoutPickerItem(layoutID: id, harness: harness)
        }
      }
      .pickerStyle(.menu)
    }
  }
}
