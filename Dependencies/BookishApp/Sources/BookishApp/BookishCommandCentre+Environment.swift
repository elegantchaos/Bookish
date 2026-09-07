// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// The environment key for Bookish's application-owned command boundary.
private struct BookishCommandCentreKey: EnvironmentKey {
  /// The absence of a command boundary outside the Bookish application shell.
  static let defaultValue: BookishCommandCentre? = nil
}

extension EnvironmentValues {
  /// The command boundary shared by Bookish SwiftUI content.
  public var bookishCommandCentre: BookishCommandCentre? {
    get { self[BookishCommandCentreKey.self] }
    set { self[BookishCommandCentreKey.self] = newValue }
  }
}
