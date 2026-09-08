// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishRecordView
import Settings
import SwiftUI

#if DEBUG
  /// Debug-only mutation history browser kept outside the main record UI.
  public struct BookishMutationDebugView: View {
    /// The datastore coordinator used to load mutations.
    private let harness: BookishHarness

    /// The command boundary used to report mutation-loading failures.
    @Environment(\.bookishCommandCentre) private var commander

    /// Whether mutation diagnostics are available.
    @AppStorage(.isDeveloperMode) private var isDeveloperMode

    /// The mutations currently displayed in the browser.
    @State private var mutations: [MutationRecord] = []

    /// The selected mutation identifier.
    @State private var selectedMutationID: MutationID?

    /// Creates the mutation debug window content.
    public init(harness: BookishHarness) {
      self.harness = harness
    }

    /// The SwiftUI content for the mutation debug window.
    public var body: some View {
      if isDeveloperMode {
        mutationBrowser
      } else {
        ContentUnavailableView(
          "Developer Mode Required", systemImage: "hammer",
          description: Text("Enable Developer Mode to inspect mutations."))
      }
    }

    /// The mutation history browser presented in developer mode.
    private var mutationBrowser: some View {
      NavigationSplitView {
        List(selection: $selectedMutationID) {
          ForEach(mutations) { mutation in
            BookishMutationCell(mutation: mutation)
              .tag(Optional(mutation.id))
          }
        }
        .navigationTitle("Mutations")
      } detail: {
        if let mutation = selectedMutation {
          BookishMutationView(mutation: mutation)
        } else {
          ContentUnavailableView(
            "No Mutation", systemImage: "list.bullet.rectangle",
            description: Text(harness.statusService.message))
        }
      }
      .task(id: harness.revision) {
        await load()
      }
    }

    /// The mutation selected in the list, when one exists.
    private var selectedMutation: MutationRecord? {
      guard let selectedMutationID else {
        return nil
      }

      return mutations.first { $0.id == selectedMutationID }
    }

    /// Loads mutations and selects the first available entry.
    private func load() async {
      do {
        mutations = try await harness.storageService.mutations()
        if selectedMutation == nil {
          selectedMutationID = mutations.first?.id
        }
      } catch {
        commander?.statusService.report(error: error)
      }
    }
  }
#endif
