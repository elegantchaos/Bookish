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
  private let harness: BookishHarness
  private let navigation: BookishNavigationService
  private let commander: BookishCommandCentre

  /// Whether advanced commands are available.
  @AppStorage(.isAdvancedMode) private var isAdvancedMode

  /// Whether developer commands are available.
  @AppStorage(.isDeveloperMode) private var isDeveloperMode

  #if DEBUG
    @Environment(\.openWindow) private var openWindow
  #endif

  /// Creates commands bound to a datastore harness.
  public init(
    harness: BookishHarness,
    navigation: BookishNavigationService,
    commander: BookishCommandCentre
  ) {
    self.harness = harness
    self.navigation = navigation
    self.commander = commander
  }

  public var body: some Commands {
    CommandGroup(after: .newItem) {
      harness.button(ImportInterchangeCommand())
      Menu("Import Delicious Library") {
        if isAdvancedMode {
          harness.button(ImportDeliciousLibrarySampleCommand(sample: .small))
          harness.button(ImportDeliciousLibrarySampleCommand(sample: .full))

          Divider()
        }

        harness.button(ImportOtherDeliciousLibraryCommand())
      }

      Divider()

      harness.button(ExportInterchangeCommand())

      if isAdvancedMode {
        harness.button(RevealDatastoreFolderCommand())
      }

      if isDeveloperMode {
        Divider()

        harness.button(RebuildRecordStoreCommand())
        harness.button(ResetDatastoreCommand(), role: .destructive)
      }
    }

    CommandMenu("Bookish") {
      Toggle("Advanced Mode", isOn: $isAdvancedMode)
      Toggle("Developer Mode", isOn: $isDeveloperMode)
        .disabled(isAdvancedMode == false)

      Divider()

      harness.button(MarkReadingCommand())
      harness.button(MarkFinishedCommand())

      if isDeveloperMode {
        Divider()

        harness.button(SimulateRemoteMutationCommand())
      }

      Divider()

      harness.button(SelectPreviousRecordIndexCommand())
      harness.button(SelectNextRecordIndexCommand())
      commander.button(SelectPreviousRecordCommand())
      commander.button(SelectNextRecordCommand())

      #if DEBUG
        if isDeveloperMode {
          Divider()

          harness.button(ThrowTestErrorCommand())

          Button("Show Mutation Debug Window") {
            openWindow(id: BookishWindow.mutationDebug.rawValue)
          }
        }
      #endif
    }
  }
}
