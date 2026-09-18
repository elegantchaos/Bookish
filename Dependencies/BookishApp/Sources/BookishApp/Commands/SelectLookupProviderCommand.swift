// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup
import Commands
import CommandsUI
import Icons

/// Selects the provider used by subsequent metadata lookups.
public struct SelectLookupProviderCommand<Centre: BookishLookupWorkflowProvider>: CommandWithUI {
  /// The command does not return a value after selecting a provider.
  public typealias ResultType = Void

  /// The provider selected by the user.
  public let providerID: BookLookupProviderID

  /// The stable command identifier.
  public let id = "lookup.select-provider"

  /// Creates a command for the selected provider.
  public init(_ providerID: BookLookupProviderID) {
    self.providerID = providerID
  }

  /// Enables selection only for a provider that can execute requests.
  public func availability(centre: Centre) -> CommandAvailability {
    !centre.lookupWorkflow.isLookingUp && centre.lookupWorkflow.isProviderSupported(providerID)
      ? .enabled : .disabled
  }

  /// Returns the user-facing command name.
  public func name(centre _: Centre) -> String { "Select Lookup Provider" }

  /// Returns the standard lookup-provider selection icon.
  public func icon(centre _: Centre) -> Icon { Icon("magnifyingglass") }

  /// Explains that the provider will be selected for later lookup requests.
  public func help(centre _: Centre) -> String? {
    "Use this provider for metadata lookups."
  }

  /// Selects the provider through the lookup workflow.
  public func perform(centre: Centre) async throws {
    centre.lookupWorkflow.selectProvider(providerID)
  }
}
