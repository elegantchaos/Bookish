// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Commands

extension BookishHarness: CommandCentre {
  /// Displays fire-and-forget command failures in the datastore status bar.
  public func recordCommandFailure<C: Command>(_ command: C, error: any Error)
  where C.Centre == BookishHarness {
    report(error: error)
  }
}

