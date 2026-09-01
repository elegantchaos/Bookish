// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 04/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Application
import Observation
import SwiftUI

/// Application-shell engine for the datastore.
///
/// The engine lets the datastore use the shared `Application` startup state
/// machine while keeping datastore-specific state in `BookishHarness`.
@MainActor
@Observable
public final class BookishEngine {
  /// Current state of the shared application loop.
  public var state: AppState

  /// Startup task owned by the shared application loop.
  @ObservationIgnored public var startupTask: Task<Void, Never>?

  /// Datastore coordinator used by the datastore UI and commands.
  @ObservationIgnored public let harness: BookishHarness

  /// Navigation and routing service for the datastore record browser.
  @ObservationIgnored public let navigation: BookishNavigationService

  /// Creates an engine with a new harness using the supplied navigation service.
  public init(
    navigation: BookishNavigationService = BookishNavigationService()
  ) {
    state = .uninitialised
    startupTask = nil
    self.navigation = navigation
    self.harness = BookishHarness(navigation: navigation)
  }

  /// Creates an engine around an existing harness and its injected navigation service.
  public init(harness: BookishHarness) {
    state = .uninitialised
    startupTask = nil
    self.navigation = harness.navigation
    self.harness = harness
  }

  /// Starts the standard shared application loop.
  public func start() {
    standardLoop()
  }

  /// Builds the root view managed by the shared application shell.
  public func rootContent() -> some View {
    rootView {
      BookishHarnessView(harness: harness, loadsOnAppear: false)
    } startup: {
      ProgressView()
    }
  }
}

extension BookishEngine: AppEngine {
  /// No synchronous startup is required by the datastore.
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

  /// Injects services that are available before startup completes.
  public var startupInjector: some ViewModifier {
    BookishEnvironmentInjector(navigation: navigation)
  }

  /// Injects running services into datastore content.
  public var runningInjector: some ViewModifier {
    BookishEnvironmentInjector(navigation: navigation)
  }
}

/// Identity environment injector used to satisfy `AppEngine`'s shell contract.
private struct BookishEnvironmentInjector: ViewModifier {
  /// Navigation service to expose to datastore SwiftUI content.
  let navigation: BookishNavigationService

  /// Injects datastore services into SwiftUI content.
  func body(content: Content) -> some View {
    content
      .environment(navigation)
  }
}
