// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup
import Observation

/// Owns temporary UI state for querying Bookish metadata providers.
@MainActor
@Observable
public final class BookishLookupWorkflowService {
  /// The provider coordinator that executes lookup work.
  @ObservationIgnored private let lookup: BookLookupService

  /// The providers offered by the temporary lookup workflow.
  @ObservationIgnored public private(set) var providers: [any BookLookupProvider]

  /// The provider selected by the user.
  public var selectedProviderID: String

  /// The current lookup query.
  public var query = ""

  /// The candidates returned by the selected provider.
  public private(set) var candidates: [BookLookupCandidate] = []

  /// The failures returned by the selected provider.
  public private(set) var failures: [BookLookupFailure] = []

  /// Whether a query is in progress.
  public private(set) var isLookingUp = false

  /// Creates a workflow backed by application-configured lookup providers.
  public init(providers: [any BookLookupProvider]) {
    guard let selectedProvider = providers.first else {
      fatalError("Bookish requires at least one configured lookup provider.")
    }
    self.providers = providers
    lookup = BookLookupService(providers: providers)
    selectedProviderID = selectedProvider.id
  }

  /// Replaces application-configured providers and preserves selection when possible.
  public func configureProviders(_ providers: [any BookLookupProvider]) async {
    guard let fallbackProvider = providers.first else {
      fatalError("Bookish requires at least one configured lookup provider.")
    }
    self.providers = providers
    await lookup.replaceProviders(with: providers)
    if providers.contains(where: { $0.id == selectedProviderID }) == false {
      selectedProviderID = fallbackProvider.id
    }
    candidates = []
    failures = []
  }

  /// Executes the selected provider for the current query.
  public func lookupBooks() async {
    guard query.isEmpty == false else { return }
    isLookingUp = true
    defer { isLookingUp = false }
    let result = await lookup.lookupBooks(
      matching: BookLookupQuery(query),
      using: [selectedProviderID]
    )
    candidates = result.candidates
    failures = result.failures
  }
}
