// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup
import Foundation
import Observation
import Settings

/// Owns temporary UI state for querying Bookish metadata providers.
@MainActor
@Observable
public final class BookishLookupWorkflowService: BookishLookupWorkflow {
  /// The provider coordinator that executes lookup work.
  @ObservationIgnored private let lookup: BookLookupService

  /// The providers offered by the temporary lookup workflow.
  @ObservationIgnored public private(set) var providers: [any BookLookupProvider]

  /// The provider selected by the user.
  public var selectedProviderID: BookLookupProviderID

  /// The application settings used to restore and persist the selected provider.
  private let settings: UserDefaults

  /// The current lookup query.
  public var query = ""

  /// The candidates returned by the selected provider.
  public private(set) var candidates: [BookLookupCandidate] = []

  /// The failures returned by the selected provider.
  public private(set) var failures: [BookLookupFailure] = []

  /// Whether a query is in progress.
  public private(set) var isLookingUp = false

  /// Creates a workflow backed by application-configured lookup providers.
  public init(providers: [any BookLookupProvider], settings: UserDefaults) {
    self.providers = providers
    lookup = BookLookupService(providers: providers)
    self.settings = settings
    selectedProviderID = Self.selectedProviderID(in: providers, settings: settings)
  }

  /// Replaces application-configured providers and preserves selection when possible.
  public func configureProviders(_ providers: [any BookLookupProvider]) async {
    self.providers = providers
    await lookup.replaceProviders(with: providers)
    selectedProviderID = Self.resolvedProviderID(in: providers, preferred: selectedProviderID)
    settings.set(selectedProviderID, forKey: .bookLookupProvider)
    candidates = []
    failures = []
  }

  /// Selects a supported provider and persists the selection in application settings.
  public func selectProvider(_ providerID: BookLookupProviderID) {
    guard isProviderSupported(providerID) else { return }
    selectedProviderID = providerID
    settings.set(providerID, forKey: .bookLookupProvider)
  }

  /// Returns whether the identified provider can execute requests.
  public func isProviderSupported(_ providerID: BookLookupProviderID) -> Bool {
    providers.first(where: { $0.id == providerID })?.isSupported == true
  }

  /// Whether the provider selected for the workflow can execute requests.
  public var isSelectedProviderSupported: Bool {
    isProviderSupported(selectedProviderID)
  }

  /// Executes the selected provider for the current query.
  public func lookupBooks() async {
    guard !query.isEmpty else { return }
    isLookingUp = true
    defer { isLookingUp = false }
    let result = await lookup.lookupBooks(
      matching: BookLookupQuery(query),
      using: [selectedProviderID]
    )
    candidates = result.candidates
    failures = result.failures
  }

  /// Resolves the persisted provider preference when it remains available.
  static func selectedProviderID(
    in providers: [any BookLookupProvider],
    settings: UserDefaults
  ) -> BookLookupProviderID {
    resolvedProviderID(in: providers, preferred: settings.value(forKey: .bookLookupProvider))
  }

  /// Selects a supported preferred provider or the first supported fallback.
  private static func resolvedProviderID(
    in providers: [any BookLookupProvider],
    preferred: BookLookupProviderID
  ) -> BookLookupProviderID {
    if providers.contains(where: { $0.id == preferred && $0.isSupported }) {
      return preferred
    }
    guard let fallback = providers.first(where: \.isSupported) else {
      fatalError("Bookish requires at least one supported lookup provider.")
    }
    return fallback.id
  }
}
