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
    /// Loads mutations and signals when they should be reloaded.
    @Environment(BookishStorageService.State.self) private var storage

    /// Reports mutation-loading failures and supplies the empty-state message.
    @Environment(BookishStatusService.State.self) private var status

    /// Whether mutation diagnostics are available.
    @AppStorage(.featureMode) private var featureMode

    /// The mutations currently displayed in the browser.
    @State private var mutations: [MutationRecord] = []

    /// The selected mutation identifier.
    @State private var selectedMutationID: MutationID?

    /// Creates the mutation debug window content.
    public init() {}

    /// The SwiftUI content for the mutation debug window.
    public var body: some View {
      if featureMode.showsDevelopment {
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
            description: Text(status.message))
        }
      }
      .task(id: storage.revision) {
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
        mutations = try await storage.mutations()
        if selectedMutation == nil {
          selectedMutationID = mutations.first?.id
        }
      } catch {
        status.report(error: error)
      }
    }
  }
#endif
