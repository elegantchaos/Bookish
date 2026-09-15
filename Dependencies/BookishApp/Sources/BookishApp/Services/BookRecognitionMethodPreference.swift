// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCapture
import Foundation
import Settings

/// Stores the recognizer selected for future book captures.
@MainActor
struct BookRecognitionMethodPreference {
  /// The application settings store that survives app launches.
  private let defaults: UserDefaults

  /// Creates a preference backed by the supplied settings store.
  init(defaults: UserDefaults = .standard) {
    self.defaults = defaults
  }

  /// Returns the stored method when it is registered, otherwise the first registered method.
  func recognizerID(in registry: BookRecognizerRegistry) -> String {
    let storedID = defaults.value(forKey: .bookRecognitionProvider)
    if registry.recognizerIDs.contains(storedID) {
      return storedID
    }

    guard let fallbackID = registry.recognizerIDs.first else {
      fatalError("Book recognition requires at least one registered method.")
    }
    return fallbackID
  }

  /// Saves the method that should be restored for the next capture workflow.
  func save(recognizerID: String) {
    defaults.set(recognizerID, forKey: .bookRecognitionProvider)
  }
}
