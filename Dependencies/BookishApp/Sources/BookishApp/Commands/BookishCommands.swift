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
import SwiftUI

#if canImport(AppKit)
  import AppKit
#endif

/// macOS menu commands for the datastore.
public struct BookishCommands: Commands {
  private let harness: BookishHarness
  private let navigation: BookishNavigationService

  #if DEBUG
    @Environment(\.openWindow) private var openWindow
  #endif

  /// Creates commands bound to a datastore harness.
  public init(harness: BookishHarness, navigation: BookishNavigationService) {
    self.harness = harness
    self.navigation = navigation
  }

  public var body: some Commands {
    CommandGroup(after: .newItem) {
      harness.button(ImportInterchangeCommand())
      Menu("Import Delicious Library") {
        harness.button(ImportDeliciousLibrarySampleCommand(sample: .small))
        harness.button(ImportDeliciousLibrarySampleCommand(sample: .full))

        Divider()

        harness.button(ImportOtherDeliciousLibraryCommand())
      }

      Divider()

      harness.button(ExportInterchangeCommand())
      harness.button(RevealDatastoreFolderCommand())

      Divider()

      harness.button(RebuildRecordStoreCommand())
      harness.button(ResetDatastoreCommand(), role: .destructive)
    }

    CommandMenu("Bookish") {
      harness.button(MarkReadingCommand())
      harness.button(MarkFinishedCommand())

      Divider()

      harness.button(SimulateRemoteMutationCommand())

      Divider()

      harness.button(SelectPreviousRecordIndexCommand())
      harness.button(SelectNextRecordIndexCommand())
      navigation.button(SelectPreviousRecordCommand())
      navigation.button(SelectNextRecordCommand())

      #if DEBUG
        Divider()

        harness.button(ThrowTestErrorCommand())

        Button("Show Mutation Debug Window") {
          openWindow(id: BookishWindow.mutationDebug.rawValue)
        }
      #endif
    }
  }
}
