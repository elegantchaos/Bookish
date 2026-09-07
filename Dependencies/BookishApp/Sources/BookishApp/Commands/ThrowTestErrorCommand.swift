// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CommandsUI
import Icons

#if DEBUG
  /// Error emitted by the datastore command used to exercise user-facing error reporting.
  private enum BookishTestCommandError: LocalizedError {
    /// The deliberate failure case.
    case intentional

    /// Explains that the error was triggered by the diagnostic command.
    var errorDescription: String? {
      "This is a test command error."
    }
  }

  /// Deliberately fails so the datastore can verify command error presentation.
  public struct ThrowTestErrorCommand<Centre: BookishRecordActionsProvider>: CommandWithUI {
    public typealias ResultType = Void

    public let id = "datastore.throw-test-error"

    /// Creates the diagnostic command.
    public init() {
    }

    public func name(centre: Centre) -> String {
      "Throw Test Error"
    }

    public func icon(centre: Centre) -> Icon {
      Icon("exclamationmark.triangle")
    }

    public func help(centre: Centre) -> String? {
      "Tests whether a command failure appears in the status bar."
    }

    public func perform(centre: Centre) async throws {
      throw BookishTestCommandError.intentional
    }
  }
#endif
