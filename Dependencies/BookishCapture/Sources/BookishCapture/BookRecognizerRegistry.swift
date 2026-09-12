// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Stores the recognition providers available to the application.
public final class BookRecognizerRegistry {
  /// Recognizers indexed by their stable identifiers.
  private var recognizersByID: [String: any BookRecognizer] = [:]

  /// Creates an empty recognizer registry.
  public init() {}

  /// Registers the recognizers bundled with Bookish.
  public func registerDefaultRecognizers() {
    register(FakeBookRecognizer())
    register(OnDeviceBookRecognizer())
    register(CloudComputeBookRecognizer())
  }

  /// Adds or replaces a recognizer with the same identifier.
  public func register(_ recognizer: any BookRecognizer) {
    recognizersByID[recognizer.id] = recognizer
  }

  /// Returns the recognizer registered for an identifier.
  public func recognizer(for identifier: String) -> any BookRecognizer {
    guard let recognizer = recognizersByID[identifier] else {
      fatalError("No book recognizer is registered for identifier: \(identifier)")
    }
    return recognizer
  }

  /// The registered recognizer identifiers in ascending order.
  public var recognizerIDs: [String] {
    recognizersByID.keys.sorted()
  }

  /// The registered recognizers in unspecified order.
  public var recognizers: [any BookRecognizer] {
    Array(recognizersByID.values)
  }
}
