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
  private let engine: BookishEngine

  /// Whether advanced commands are available.
  @AppStorage(.isAdvancedMode) private var isAdvancedMode

  /// Whether developer commands are available.
  @AppStorage(.isDeveloperMode) private var isDeveloperMode

  #if DEBUG
    @Environment(\.openWindow) private var openWindow
  #endif

  /// Creates commands bound to the supplied command centre.
  public init(engine: BookishEngine) {
    self.engine = engine
  }

  public var body: some Commands {
    CommandGroup(after: .newItem) {
      engine.button(ImportInterchangeCommand())
      Menu("Import Delicious Library") {
        if isAdvancedMode {
          engine.button(ImportDeliciousLibrarySampleCommand(sample: .small))
          engine.button(ImportDeliciousLibrarySampleCommand(sample: .full))

          Divider()
        }

        engine.button(ImportOtherDeliciousLibraryCommand())
      }

      Divider()

      engine.button(ExportInterchangeCommand())

      if isAdvancedMode {
        engine.button(RevealDatastoreFolderCommand())
      }

      if isDeveloperMode {
        Divider()

        engine.button(RebuildRecordStoreCommand())
        engine.button(ResetDatastoreCommand(), role: .destructive)
      }
    }

    CommandMenu("Bookish") {
      Toggle("Advanced Mode", isOn: $isAdvancedMode)
      Toggle("Developer Mode", isOn: $isDeveloperMode)
        .disabled(isAdvancedMode == false)

      Divider()

      engine.button(MarkReadingCommand())
      engine.button(MarkFinishedCommand())

      if isDeveloperMode {
        Divider()

        engine.button(SimulateRemoteMutationCommand())
      }

      Divider()

      engine.button(SelectPreviousRecordIndexCommand())
      engine.button(SelectNextRecordIndexCommand())
      engine.button(SelectPreviousRecordCommand())
      engine.button(SelectNextRecordCommand())

      #if DEBUG
        if isDeveloperMode {
          Divider()

          engine.button(ThrowTestErrorCommand())

          Button("Show Mutation Debug Window") {
            openWindow(id: BookishWindow.mutationDebug.rawValue)
          }
        }
      #endif
    }
  }
}
