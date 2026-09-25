// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import Commands
import Observation

/// Owns status reporting and the state displayed by Bookish views.
@MainActor
public final class BookishStatusService {
  /// The status operations available to commands and collaborating services.
  @MainActor
  public protocol API {
    /// Reports a user-facing message.
    func report(message: String)

    /// Reports an error using its localized description.
    func report(error: Error)
  }

  /// Vends status reporting to commands.
  @MainActor
  public protocol Provider: CommandCentre {
    /// The status API used by the command.
    var statusService: any API { get }
  }

  /// The stable, observable status read by views.
  @MainActor
  @Observable
  public final class State {
    /// The current user-facing status message.
    public fileprivate(set) var message: String

    /// The import progress currently shown by the user interface.
    public fileprivate(set) var importProgress: BookishImportProgress?

    /// Creates the initial status projection.
    fileprivate init(message: String) {
      self.message = message
      importProgress = nil
    }

    /// Shows a failure encountered while loading or presenting view content.
    public func report(error: Error) {
      message = error.localizedDescription
    }
  }

  /// The view-facing status projection.
  public let state: State

  /// Creates a status service with its initial user-facing message.
  public init(message: String = "Loading") {
    state = State(message: message)
  }

  /// Updates the displayed import progress and its accompanying message.
  public func report(progress: BookishImportProgress) {
    state.importProgress = progress
    state.message = progress.message
  }

  /// Stops displaying import progress while retaining the latest message.
  public func clearImportProgress() {
    state.importProgress = nil
  }
}

extension BookishStatusService: BookishStatusService.API {
  public func report(message: String) {
    state.message = message
  }

  public func report(error: Error) {
    state.report(error: error)
  }
}

extension BookishEngine: BookishStatusService.Provider {
}
