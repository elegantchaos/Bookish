// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Stores the recognition providers available to the application.
public final class BookRecognitionProviderRegistry {
  /// Recognition providers indexed by their stable identifiers.
  private var recognitionProvidersByID: [BookRecognitionProviderID: any BookRecognitionProvider] =
    [:]

  /// Creates a registry with the supplied initial recognition providers.
  public init(recognitionProviders: [any BookRecognitionProvider] = []) {
    for recognitionProvider in recognitionProviders {
      register(recognitionProvider)
    }
  }

  /// Registers the recognition providers bundled with Bookish.
  public func registerDefaultRecognitionProviders() {
    register(FakeBookRecognitionProvider())
    register(OnDeviceBookRecognitionProvider())
    register(CloudComputeBookRecognitionProvider())
    register(OCRBookRecognitionProvider())
  }

  /// Adds or replaces a recognition provider with the same identifier.
  public func register(_ recognitionProvider: any BookRecognitionProvider) {
    recognitionProvidersByID[recognitionProvider.id] = recognitionProvider
  }

  /// Removes the recognition provider with the supplied identifier, if it is registered.
  public func unregister(_ identifier: BookRecognitionProviderID) {
    recognitionProvidersByID[identifier] = nil
  }

  /// Replaces the complete set of configured recognition providers.
  public func replaceRecognitionProviders(with recognitionProviders: [any BookRecognitionProvider])
  {
    recognitionProvidersByID = [:]
    for recognitionProvider in recognitionProviders {
      register(recognitionProvider)
    }
  }

  /// Returns the recognition provider registered for an identifier.
  public func recognitionProvider(for identifier: BookRecognitionProviderID)
    -> any BookRecognitionProvider
  {
    guard let recognitionProvider = recognitionProvidersByID[identifier] else {
      fatalError("No book recognition provider is registered for identifier: \(identifier)")
    }
    return recognitionProvider
  }

  /// The registered recognition provider identifiers in ascending order.
  public var recognitionProviderIDs: [BookRecognitionProviderID] {
    BookRecognitionProviderID
      .allCases
      .filter { recognitionProvidersByID[$0] != nil }
  }

  /// The registered recognition providers in unspecified order.
  public var recognitionProviders: [any BookRecognitionProvider] {
    Array(recognitionProvidersByID.values)
  }
}
