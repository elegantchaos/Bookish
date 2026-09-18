// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Coordinates a lookup across independently registered metadata providers.
///
/// Providers are intentionally isolated: a failed adapter produces a failure entry
/// while candidates from the other adapters remain available for review.
public actor BookLookupService {
  /// Stores providers keyed by their stable identifiers.
  private var providersByID: [String: any BookLookupProvider]

  /// Creates a service with the supplied initial providers.
  public init(providers: [any BookLookupProvider] = []) {
    providersByID = [:]
    for provider in providers {
      providersByID[provider.id] = provider
    }
  }

  /// Registers a provider, replacing any provider with the same identifier.
  public func register(_ provider: any BookLookupProvider) {
    providersByID[provider.id] = provider
  }

  /// Registers the lookup providers bundled with Bookish.
  public func registerDefaultProviders() {
    register(FakeBookLookupProvider())
    register(OpenLibraryLookupProvider())
  }

  /// Removes the provider with the supplied identifier, if it is registered.
  public func unregister(_ providerID: String) {
    providersByID[providerID] = nil
  }

  /// Replaces the complete set of configured providers.
  public func replaceProviders(with providers: [any BookLookupProvider]) {
    providersByID = [:]
    for provider in providers {
      register(provider)
    }
  }

  /// Returns registered providers in ascending identifier order.
  public var providers: [any BookLookupProvider] {
    providersByID.values.sorted { $0.id < $1.id }
  }

  /// Looks up a query through every supported provider.
  public func lookupBooks(
    matching query: BookLookupQuery,
    using providerIDs: Set<String>? = nil
  ) async -> BookLookupResult {
    let providers = providersByID.values.filter {
      $0.isSupported && (providerIDs?.contains($0.id) ?? true)
    }
    return await withTaskGroup(of: ProviderResult.self, returning: BookLookupResult.self) { group in
      for provider in providers {
        group.addTask {
          do {
            return .success(try await provider.lookupBooks(matching: query))
          } catch {
            return .failure(BookLookupFailure(providerID: provider.id, error: error))
          }
        }
      }

      var candidates: [BookLookupCandidate] = []
      var failures: [BookLookupFailure] = []
      for await result in group {
        switch result {
        case .success(let providerCandidates):
          candidates.append(contentsOf: providerCandidates)
        case .failure(let failure):
          failures.append(failure)
        }
      }
      return BookLookupResult(candidates: candidates, failures: failures)
    }
  }
}
