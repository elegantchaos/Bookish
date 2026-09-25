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

  /// How much optional and diagnostic functionality is available.
  @AppStorage(.featureMode) private var featureMode

  #if DEBUG
    @Environment(\.openWindow) private var openWindow
  #endif

  /// Creates commands bound to the supplied command centre.
  public init(engine: BookishEngine) {
    self.engine = engine
  }

  public var body: some Commands {
    CommandGroup(replacing: .newItem) {
      Menu("New") {
        ForEach(BookishNewRecordType.allCases, id: \.self) { type in
          engine.button(NewRecordCommand(type: type))
        }
      }
    }

    CommandGroup(replacing: .importExport) {
      Divider()

      Menu("Import") {
        engine.button(ImportInterchangeCommand()) { Text("Interchange File…") }
        Menu("Kindle Library") {
          engine.button(ImportKindleLibrarySampleCommand())
          engine.button(ImportKindleLibraryCommand())
        }
        Menu("Delicious Library") {
          if featureMode.showsAdvanced {
            engine.button(ImportDeliciousLibrarySampleCommand(sample: .small))
            engine.button(ImportDeliciousLibrarySampleCommand(sample: .full))

            Divider()
          }

          engine.button(ImportOtherDeliciousLibraryCommand())
        }
      }

      Divider()

      engine.button(ExportInterchangeCommand())
    }

    CommandMenu("Bookish") {
      BookishFeatureModePicker(selection: $featureMode)

      Divider()

      engine.button(MarkReadingCommand())
      engine.button(MarkFinishedCommand())

      if featureMode.showsDevelopment {
        Divider()

        engine.button(SimulateRemoteMutationCommand())
      }

      Divider()

      engine.button(SelectPreviousRecordIndexCommand())
      engine.button(SelectNextRecordIndexCommand())
      engine.button(SelectPreviousRecordCommand())
      engine.button(SelectNextRecordCommand())

      #if DEBUG
        if featureMode.showsDevelopment {
          Divider()

          engine.button(ThrowTestErrorCommand())

          Button("Show Mutation Debug Window") {
            openWindow(id: BookishWindow.mutationDebug.rawValue)
          }
        }
      #endif
    }

    if featureMode.showsAdvanced {
      CommandMenu("Debug") {
        engine.button(RevealDatastoreFolderCommand())

        if featureMode.showsDevelopment {
          Divider()

          engine.button(RebuildRecordStoreCommand())
          engine.button(ResetDatastoreCommand(), role: .destructive)
        }
      }
    }
  }
}
