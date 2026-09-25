// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup
import SwiftUI

/// Configures the provider used for metadata lookup requests.
struct LookupSettingsView: View {
  /// The command source used to select a lookup provider.
  @Environment(BookishCommander.self) private var commander

  /// The lookup workflow that supplies provider state.
  @Environment(BookishLookupWorkflowService.State.self) private var lookup

  /// The settings form.
  var body: some View {
    let selectedProvider = lookup.providers.first { $0.id == lookup.selectedProviderID }

    Form {
      Section {
        LabeledContent("Lookup Service") {
          VStack(alignment: .leading) {
            Menu {
              ForEach(lookup.providers, id: \.id) { provider in
                commander.button(SelectLookupProviderCommand(provider.id)) {
                  HStack {
                    Image(systemName: "checkmark")
                      .opacity(provider.id == lookup.selectedProviderID ? 1 : 0)
                    Text(provider.label)
                  }
                }
                .disabled(!provider.isSupported)
              }
            } label: {
              Text(selectedProvider?.label ?? "Unavailable")
            }

            if let selectedProvider {
              Text(selectedProvider.description)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
          }
        }
      }
      .disabled(lookup.isLookingUp)

      Divider()
        .padding(.vertical)

      Section {
        ForEach(lookup.providers, id: \.id) { provider in
          LookupProviderSettingsRow(provider: provider)
        }
      } header: {
        Label("Provider Information", systemImage: "info.circle")
      }
    }
    .formStyle(.columns)
    .fixedSize(horizontal: false, vertical: true)
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}

#Preview {
  let engine = BookishEngine()
  LookupSettingsView()
    .modifier(BookishEnvironmentInjector(engine: engine))
}
