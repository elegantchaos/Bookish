// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishDatastore
import BookishRecordView
import SwiftUI

#if DEBUG
  /// Debug-only mutation history browser kept outside the main record UI.
  public struct BookishMutationDebugView: View {
    private let harness: BookishHarness
    @State private var mutations: [MutationRecord] = []
    @State private var selectedMutationID: MutationID?

    /// Creates the mutation debug window content.
    public init(harness: BookishHarness) {
      self.harness = harness
    }

    /// The SwiftUI content for the mutation debug window.
    public var body: some View {
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
            "No Mutation", systemImage: "list.bullet.rectangle", description: Text(harness.status))
        }
      }
      .task(id: harness.revision) {
        await load()
      }
    }

    private var selectedMutation: MutationRecord? {
      guard let selectedMutationID else {
        return nil
      }

      return mutations.first { $0.id == selectedMutationID }
    }

    private func load() async {
      do {
        mutations = try await harness.mutations()
        if selectedMutation == nil {
          selectedMutationID = mutations.first?.id
        }
      } catch {
        harness.report(error: error)
      }
    }
  }
#endif
