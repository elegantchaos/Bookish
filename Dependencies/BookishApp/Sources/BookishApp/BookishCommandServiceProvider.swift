// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands

/// Vends the datastore-facing Bookish service to commands.
@MainActor
public protocol BookishHarnessProvider: CommandCentre {
  /// The datastore-facing Bookish service.
  var harness: BookishHarness { get }
}

/// Vends browser routing to navigation commands.
@MainActor
public protocol BookishNavigationServiceProvider: CommandCentre {
  /// The browser-routing service.
  var navigationService: BookishNavigationService { get }
}

extension BookishCommandCentre: BookishHarnessProvider, BookishNavigationServiceProvider {
}

extension BookishHarness: BookishHarnessProvider {
  public var harness: BookishHarness { self }
}
