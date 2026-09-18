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
  @Environment(BookishLookupWorkflowService.self) private var lookup

  /// The settings form.
  var body: some View {
    let selectedProvider = lookup.providers.first { $0.id == lookup.selectedProviderID }

    Form {
      Section {
        HStack {
          Text("Lookup Service")
          Spacer()
          Menu {
            ForEach(lookup.providers, id: \.id) { provider in
              commander.button(SelectLookupProviderCommand(provider.id)) {
                HStack {
                  Image(systemName: "checkmark")
                    .opacity(provider.id == lookup.selectedProviderID ? 1 : 0)
                  Text(provider.label)
                }
              }
              .disabled(provider.isSupported == false)
            }
          } label: {
            Text(selectedProvider?.label ?? "Unavailable")
          }
        }

        if let selectedProvider {
          Text(selectedProvider.description)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      .disabled(lookup.isLookingUp)

      Section("Providers") {
        ForEach(lookup.providers, id: \.id) { provider in
          LookupProviderSettingsRow(provider: provider)
        }
      }
    }
  }
}

#Preview {
  let engine = BookishEngine()
  LookupSettingsView()
    .modifier(BookishEnvironmentInjector(engine: engine))
}
