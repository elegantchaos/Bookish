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

  /// Application-owned command boundary for Bookish services.
  @ObservationIgnored public let commander: BookishCommandCentre

  /// Navigation and routing service for the datastore record browser.
  @ObservationIgnored public let navigation: BookishNavigationService

  /// Creates an engine with a new harness using the supplied navigation service.
  public init(
    navigation: BookishNavigationService = BookishNavigationService()
  ) {
    let harness = BookishHarness(navigation: navigation)
    state = .uninitialised
    startupTask = nil
    self.navigation = navigation
    self.harness = harness
    commander = BookishCommandCentre(harness: harness)
  }

  /// Creates an engine around an existing harness and its injected navigation service.
  public init(harness: BookishHarness) {
    state = .uninitialised
    startupTask = nil
    self.navigation = harness.navigation
    self.harness = harness
    commander = BookishCommandCentre(harness: harness)
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
