// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup
import BookishRecord
import SwiftUI

/// Provides a temporary interface for querying the selected metadata provider.
struct BookLookupView: View {
  /// The workflow state for lookup controls and results.
  @Environment(BookishLookupWorkflowService.self) private var lookup

  /// The temporary query interface.
  var body: some View {
    @Bindable var lookup = lookup
    Form {
      Section("Query") {
        TextField("ISBN, title, or author", text: $lookup.query)
          .textFieldStyle(.roundedBorder)

        Button("Look Up", systemImage: "magnifyingglass", action: lookupBooks)
          .disabled(
            lookup.query.isEmpty || lookup.isLookingUp
              || lookup.isSelectedProviderSupported == false
          )
      }

      if lookup.isLookingUp {
        Section {
          ProgressView("Looking up books")
        }
      }

      if lookup.candidates.isEmpty == false {
        Section("Candidates") {
          ForEach(lookup.candidates) { candidate in
            VStack(alignment: .leading) {
              Text(candidate.record.string(BookishRecordKey.name) ?? candidate.title)
                .font(.headline)
              if candidate.authors.isEmpty == false {
                Text(candidate.authors.formatted(.list(type: .and)))
                  .foregroundStyle(.secondary)
              }
              Text(candidate.providerID.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }
      }

      if lookup.failures.isEmpty == false {
        Section("Provider Failures") {
          ForEach(lookup.failures, id: \.providerID) { failure in
            Text("\(failure.providerID.rawValue): \(failure.error.localizedDescription)")
          }
        }
      }
    }
    .navigationTitle("Lookup")
  }

  /// Starts one lookup task for the current form state.
  private func lookupBooks() {
    Task { await lookup.lookupBooks() }
  }
}

#Preview {
  let engine = BookishEngine()
  BookLookupView()
    .modifier(BookishEnvironmentInjector(engine: engine))
}
