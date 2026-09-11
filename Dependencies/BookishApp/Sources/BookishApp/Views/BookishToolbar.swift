// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import CommandsUI
import Settings
import SwiftUI

/// Provides the browser actions and layout picker in the main toolbar.
struct BookishToolbar: ToolbarContent {
  /// The datastore coordinator backing toolbar actions and selection.
  let harness: BookishUIStateService

  /// The application-owned command boundary for toolbar actions.
  @Environment(BookishEngine.self) private var commander

  /// Whether developer-only toolbar actions are available.
  @AppStorage(.isDeveloperMode) private var isDeveloperMode

  /// Whether advanced toolbar controls are available.
  @AppStorage(.isAdvancedMode) private var isAdvancedMode

  /// The toolbar items for import, export, record actions, and layouts.
  var body: some ToolbarContent {
    ToolbarItem {
      commander.button(ImportInterchangeCommand())
        .labelStyle(.iconOnly)
    }

    ToolbarItem {
      commander.button(ExportInterchangeCommand())
        .labelStyle(.iconOnly)
    }

    commander.toolbarItem(MarkReadingCommand())
    commander.toolbarItem(MarkFinishedCommand())
    if isDeveloperMode {
      commander.toolbarItem(SimulateRemoteMutationCommand())
    }

    if isAdvancedMode {
      ToolbarItem {
        @Bindable var presentation = harness.presentation
        Picker("Layout", selection: $presentation.selectedLayoutID) {
          Text("Default").tag(Optional<BookishRecordID>.none)
          ForEach(presentation.compatibleLayoutIDs, id: \.self) { id in
            BookishLayoutPickerItem(layoutID: id, harness: harness)
          }
        }
        .pickerStyle(.menu)
      }
    }
  }
}
