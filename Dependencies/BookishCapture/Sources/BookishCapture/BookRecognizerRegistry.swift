// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Stores the recognition providers available to the application.
public final class BookRecognizerRegistry {
  /// Recognizers indexed by their stable identifiers.
  private var recognizersByID: [BookRecognizerID: any BookRecognizer] = [:]

  /// Creates a registry with the supplied initial recognizers.
  public init(recognizers: [any BookRecognizer] = []) {
    for recognizer in recognizers {
      register(recognizer)
    }
  }

  /// Registers the recognizers bundled with Bookish.
  public func registerDefaultRecognizers() {
    register(FakeBookRecognizer())
    register(OnDeviceBookRecognizer())
    register(CloudComputeBookRecognizer())
    register(OCRBookRecognizer())
  }

  /// Adds or replaces a recognizer with the same identifier.
  public func register(_ recognizer: any BookRecognizer) {
    recognizersByID[recognizer.id] = recognizer
  }

  /// Removes the recognizer with the supplied identifier, if it is registered.
  public func unregister(_ identifier: BookRecognizerID) {
    recognizersByID[identifier] = nil
  }

  /// Replaces the complete set of configured recognizers.
  public func replaceRecognizers(with recognizers: [any BookRecognizer]) {
    recognizersByID = [:]
    for recognizer in recognizers {
      register(recognizer)
    }
  }

  /// Returns the recognizer registered for an identifier.
  public func recognizer(for identifier: BookRecognizerID) -> any BookRecognizer {
    guard let recognizer = recognizersByID[identifier] else {
      fatalError("No book recognizer is registered for identifier: \(identifier)")
    }
    return recognizer
  }

  /// The registered recognizer identifiers in ascending order.
  public var recognizerIDs: [BookRecognizerID] {
    BookRecognizerID
      .allCases
      .filter { recognizersByID[$0] != nil }
  }

  /// The registered recognizers in unspecified order.
  public var recognizers: [any BookRecognizer] {
    Array(recognizersByID.values)
  }
}
