// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import BookishImporterSamples
import BookishRecord
import Commands
import CommandsUI
import Foundation
import Icons
import Settings
import SwiftUI

#if canImport(AppKit)
  import AppKit
#endif

/// macOS menu commands for the datastore.
public struct BookishCommands: Commands {
  private let commander: BookishCommandCentre

  /// Whether advanced commands are available.
  @AppStorage(.isAdvancedMode) private var isAdvancedMode

  /// Whether developer commands are available.
  @AppStorage(.isDeveloperMode) private var isDeveloperMode

  #if DEBUG
    @Environment(\.openWindow) private var openWindow
  #endif

  /// Creates commands bound to the supplied command centre.
  public init(commander: BookishCommandCentre) {
    self.commander = commander
  }

  public var body: some Commands {
    CommandGroup(after: .newItem) {
      commander.button(ImportInterchangeCommand())
      Menu("Import Delicious Library") {
        if isAdvancedMode {
          commander.button(ImportDeliciousLibrarySampleCommand(sample: .small))
          commander.button(ImportDeliciousLibrarySampleCommand(sample: .full))

          Divider()
        }

        commander.button(ImportOtherDeliciousLibraryCommand())
      }

      Divider()

      commander.button(ExportInterchangeCommand())

      if isAdvancedMode {
        commander.button(RevealDatastoreFolderCommand())
      }

      if isDeveloperMode {
        Divider()

        commander.button(RebuildRecordStoreCommand())
        commander.button(ResetDatastoreCommand(), role: .destructive)
      }
    }

    CommandMenu("Bookish") {
      Toggle("Advanced Mode", isOn: $isAdvancedMode)
      Toggle("Developer Mode", isOn: $isDeveloperMode)
        .disabled(isAdvancedMode == false)

      Divider()

      commander.button(MarkReadingCommand())
      commander.button(MarkFinishedCommand())

      if isDeveloperMode {
        Divider()

        commander.button(SimulateRemoteMutationCommand())
      }

      Divider()

      commander.button(SelectPreviousRecordIndexCommand())
      commander.button(SelectNextRecordIndexCommand())
      commander.button(SelectPreviousRecordCommand())
      commander.button(SelectNextRecordCommand())

      #if DEBUG
        if isDeveloperMode {
          Divider()

          commander.button(ThrowTestErrorCommand())

          Button("Show Mutation Debug Window") {
            openWindow(id: BookishWindow.mutationDebug.rawValue)
          }
        }
      #endif
    }
  }
}
