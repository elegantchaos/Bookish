// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import CommandsUI
import BookishRecord
import SwiftUI

struct BookishToolbar: ToolbarContent {
  var harness: BookishHarness

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
