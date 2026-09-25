// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup
import Commands
import Foundation
import Observation
import Settings

/// Owns temporary UI state for querying Bookish metadata providers.
@MainActor
public final class BookishLookupWorkflowService {
  /// The provider coordinator that executes lookup work.
  private let lookup: BookLookupService

  public let state: State

  public var providers: [any BookLookupProvider] { state.providers }
  public var selectedProviderID: BookLookupProviderID { state.selectedProviderID }
  public var query: String {
    get { state.query }
    set { state.query = newValue }
  }
  public var candidates: [BookLookupCandidate] { state.candidates }
  public var failures: [BookLookupFailure] { state.failures }
  public var isLookingUp: Bool { state.isLookingUp }
  public var canLookupBooks: Bool { state.canLookupBooks }
  public var isSelectedProviderSupported: Bool { state.isSelectedProviderSupported }

  /// The application settings used to restore and persist the selected provider.
  private let settings: UserDefaults

  /// Creates a workflow backed by application-configured lookup providers.
  public init(providers: [any BookLookupProvider], settings: UserDefaults) {
    state = State(
      providers: providers,
      selectedProviderID: Self.selectedProviderID(in: providers, settings: settings))
    lookup = BookLookupService(providers: providers)
    self.settings = settings
  }

  /// Replaces application-configured providers and preserves selection when possible.
  public func configureProviders(_ providers: [any BookLookupProvider]) async {
    state.providers = providers
    await lookup.replaceProviders(with: providers)
    state.selectedProviderID = Self.resolvedProviderID(in: providers, preferred: selectedProviderID)
    settings.set(selectedProviderID, forKey: .bookLookupProvider)
    state.candidates = []
    state.failures = []
  }

  /// Selects a supported provider and persists the selection in application settings.
  public func selectProvider(_ providerID: BookLookupProviderID) {
    guard isProviderSupported(providerID) else { return }
    state.selectedProviderID = providerID
    settings.set(providerID, forKey: .bookLookupProvider)
  }

  /// Returns whether the identified provider can execute requests.
  public func isProviderSupported(_ providerID: BookLookupProviderID) -> Bool {
    providers.first(where: { $0.id == providerID })?.isSupported == true
  }

  /// Executes the selected provider for the current query.
  public func lookupBooks() async {
    guard !query.isEmpty else { return }
    state.isLookingUp = true
    defer { state.isLookingUp = false }
    let result = await lookup.lookupBooks(
      matching: BookLookupQuery(query),
      using: [selectedProviderID]
    )
    state.candidates = result.candidates
    state.failures = result.failures
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

extension BookishLookupWorkflowService {
  @MainActor
  public protocol API: AnyObject {
    var canLookupBooks: Bool { get }
    func lookupBooks() async
    var isLookingUp: Bool { get }
    func selectProvider(_ providerID: BookLookupProviderID)
    func isProviderSupported(_ providerID: BookLookupProviderID) -> Bool
  }

  @MainActor
  public protocol Access: CommandCentre {
    var lookupWorkflowAPI: any API { get }
  }

  @MainActor
  @Observable
  public final class State {
    public fileprivate(set) var providers: [any BookLookupProvider]
    public fileprivate(set) var selectedProviderID: BookLookupProviderID
    public var query = ""
    public fileprivate(set) var candidates: [BookLookupCandidate] = []
    public fileprivate(set) var failures: [BookLookupFailure] = []
    public fileprivate(set) var isLookingUp = false

    fileprivate init(providers: [any BookLookupProvider], selectedProviderID: BookLookupProviderID)
    {
      self.providers = providers
      self.selectedProviderID = selectedProviderID
    }

    public var isSelectedProviderSupported: Bool {
      providers.first(where: { $0.id == selectedProviderID })?.isSupported == true
    }

    public var canLookupBooks: Bool {
      !query.isEmpty && !isLookingUp && isSelectedProviderSupported
    }
  }
}

extension BookishLookupWorkflowService: BookishLookupWorkflowService.API {}

extension BookishEngine: BookishLookupWorkflowService.Access {}
