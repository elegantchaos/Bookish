// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import Observation

/// Reports user-facing messages and progress for Bookish operations.
@MainActor
public protocol BookishStatus {
  /// The current user-facing status message.
  var message: String { get }

  /// The import progress currently shown by the user interface.
  var importProgress: BookishImportProgress? { get }

  /// Reports a user-facing message.
  func report(message: String)

  /// Reports an error using its localized description.
  func report(error: Error)
}

/// Owns the observable status message and import progress presented by Bookish UI.
@MainActor
@Observable
public final class BookishStatusService {
  /// The current user-facing status message.
  public private(set) var message: String

  /// The import progress currently shown by the user interface.
  public private(set) var importProgress: BookishImportProgress?

  /// Creates a status service with its initial user-facing message.
  public init(message: String = "Loading") {
    self.message = message
  }

  /// Updates the displayed import progress and its accompanying message.
  public func report(progress: BookishImportProgress) {
    importProgress = progress
    message = progress.message
  }

  /// Stops displaying import progress while retaining the latest message.
  public func clearImportProgress() {
    importProgress = nil
  }
}

extension BookishStatusService: BookishStatus {
  public func report(message: String) {
    self.message = message
  }

  public func report(error: Error) {
    message = error.localizedDescription
  }
}
