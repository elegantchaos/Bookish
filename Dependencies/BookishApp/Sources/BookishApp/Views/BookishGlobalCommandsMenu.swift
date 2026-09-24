// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Codex on 24/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

#if os(iOS)
  import BookishImporterSamples
  import Settings
  import SwiftUI

  /// Places the application commands in the visible navigation bar on compact devices.
  struct BookishGlobalCommandsToolbar: ToolbarContent {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some ToolbarContent {
      if horizontalSizeClass == .compact {
        ToolbarItem(placement: .topBarTrailing) {
          BookishGlobalCommandsMenu()
        }
      }
    }
  }

  /// Gives iPhone users access to the application's import, export, and testing commands.
  private struct BookishGlobalCommandsMenu: View {
    @Environment(BookishCommander.self) private var commander

    @AppStorage(.isAdvancedMode) private var isAdvancedMode
    @AppStorage(.isDeveloperMode) private var isDeveloperMode

    @State private var isShowingResetConfirmation = false

    var body: some View {
      let resetConfirmation = commander.confirmation(for: ResetDatastoreCommand())

      Menu("More", systemImage: "ellipsis.circle") {
        commander.button(ImportInterchangeCommand())

        Menu("Import Delicious Library", systemImage: "books.vertical") {
          commander.button(ImportOtherDeliciousLibraryCommand())

          if isAdvancedMode {
            Divider()
            commander.button(ImportDeliciousLibrarySampleCommand(sample: .small))
            commander.button(ImportDeliciousLibrarySampleCommand(sample: .full))
          }
        }

        commander.button(ExportInterchangeCommand())

        Divider()

        Toggle("Advanced Mode", isOn: $isAdvancedMode)
        Toggle("Developer Mode", isOn: $isDeveloperMode)
          .disabled(!isAdvancedMode)

        if isDeveloperMode {
          Divider()
          Button("Reset Bookish Datastore", systemImage: "trash", role: .destructive) {
            isShowingResetConfirmation = true
          }
        }
      }
      .confirmationDialog(
        resetConfirmation.title,
        isPresented: $isShowingResetConfirmation,
        titleVisibility: .visible
      ) {
        Button(resetConfirmation.confirm, role: .destructive) {
          commander.perform(ResetDatastoreCommand())
        }
        Button(resetConfirmation.cancel, role: .cancel) {}
      } message: {
        Text(resetConfirmation.message)
      }
    }
  }
#endif
