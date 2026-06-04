// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Application
import Observation
import SwiftUI

/// Application-shell engine for the datastore prototype.
///
/// The engine lets the prototype use the shared `Application` startup state
/// machine while keeping datastore-specific state in `DatastorePrototypeHarness`.
@MainActor
@Observable
public final class DatastorePrototypeEngine {
  /// Current state of the shared application loop.
  public var state: AppState

  /// Startup task owned by the shared application loop.
  @ObservationIgnored public var startupTask: Task<Void, Never>?

  /// Datastore coordinator used by the prototype UI and commands.
  @ObservationIgnored public let harness: DatastorePrototypeHarness

  /// Creates an engine around the supplied harness.
  public init(harness: DatastorePrototypeHarness = DatastorePrototypeHarness()) {
    state = .uninitialised
    startupTask = nil
    self.harness = harness
  }

  /// Starts the standard shared application loop.
  public func start() {
    standardLoop()
  }

  /// Builds the root view managed by the shared application shell.
  public func rootContent() -> some View {
    rootView {
      DatastorePrototypeHarnessView(harness: harness, loadsOnAppear: false)
    } startup: {
      ProgressView()
    }
  }
}

extension DatastorePrototypeEngine: AppEngine {
  /// No synchronous startup is required by the prototype.
  public func initialise() throws {
  }

  /// Loads and seeds the datastore while the shell presents startup UI.
  public func startup() async throws {
    await harness.load()
  }

  /// Retries startup after an error state.
  public func retry() async throws {
    await harness.load()
  }

  /// Surfaces all shell errors to the default error UI.
  public func shouldIgnore(error: any Error) -> Bool {
    false
  }

  /// No environment injection is needed before startup completes.
  public var startupInjector: some ViewModifier {
    DatastorePrototypeEnvironmentInjector()
  }

  /// No environment injection is needed after startup completes.
  public var runningInjector: some ViewModifier {
    DatastorePrototypeEnvironmentInjector()
  }
}

/// Identity environment injector used to satisfy `AppEngine`'s shell contract.
private struct DatastorePrototypeEnvironmentInjector: ViewModifier {
  /// Leaves prototype content unchanged.
  func body(content: Content) -> some View {
    content
  }
}
