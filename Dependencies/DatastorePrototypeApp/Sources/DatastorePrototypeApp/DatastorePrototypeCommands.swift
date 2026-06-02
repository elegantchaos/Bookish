import SwiftUI

/// macOS menu commands for the datastore prototype.
public struct DatastorePrototypeCommands: Commands {
  @Bindable private var harness: DatastorePrototypeHarness

  /// Creates commands bound to a prototype harness.
  public init(harness: DatastorePrototypeHarness) {
    self.harness = harness
  }

  public var body: some Commands {
    CommandGroup(after: .newItem) {
      Button("Import Interchange File...") {
        harness.requestInterchangeImport()
      }
      .keyboardShortcut("i", modifiers: [.command, .shift])

      Button("Import Delicious Library File...") {
        harness.requestDeliciousLibraryImport()
      }

      Divider()

      Button("Export Interchange File...") {
        harness.requestInterchangeExport()
      }
      .keyboardShortcut("e", modifiers: [.command, .shift])
      .disabled(harness.records.isEmpty)

      Divider()

      Button("Reset Prototype Datastore") {
        Task {
          await harness.reset()
        }
      }
    }

    CommandMenu("Prototype") {
      Button("Mark Reading") {
        Task {
          await harness.markReading()
        }
      }
      .keyboardShortcut("r", modifiers: [.command, .shift])
      .disabled(harness.selectedRecord == nil)

      Button("Mark Finished") {
        Task {
          await harness.markFinished()
        }
      }
      .keyboardShortcut("f", modifiers: [.command, .shift])
      .disabled(harness.selectedRecord == nil)

      Divider()

      Button("Simulate Remote Mutation") {
        Task {
          await harness.simulateRemoteUpdate()
        }
      }
      .disabled(harness.selectedRecord == nil)
    }
  }
}
