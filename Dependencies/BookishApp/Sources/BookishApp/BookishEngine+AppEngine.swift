// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Application
import SwiftUI

/// Connects the Bookish application engine to the shared application shell.
extension BookishEngine: AppEngine {
  /// No synchronous startup is required by the datastore.
  public func initialise() throws {
  }

  /// Loads and seeds the datastore while the shell presents startup UI.
  public func startup() async throws {
    await load()
  }

  /// Retries startup after an error state.
  public func retry() async throws {
    await load()
  }

  /// Surfaces all shell errors to the default error UI.
  public func shouldIgnore(error: any Error) -> Bool {
    false
  }

  /// Injects services that are available before startup completes.
  public var startupInjector: some ViewModifier {
    BookishEnvironmentInjector(engine: self)
  }

  /// Injects running services into datastore content.
  public var runningInjector: some ViewModifier {
    BookishEnvironmentInjector(engine: self)
  }
}
