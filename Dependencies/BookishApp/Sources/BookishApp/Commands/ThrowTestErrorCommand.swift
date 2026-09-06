//
//  File.swift
//  BookishApp
//
//  Created by Sam Deane on 06/09/2026.
//

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
  public struct ThrowTestErrorCommand: CommandWithUI {
    public typealias Centre = BookishHarness
    public typealias ResultType = Void

    public let id = "datastore.throw-test-error"

    /// Creates the diagnostic command.
    public init() {
    }

    public func name(centre: BookishHarness) -> String {
      "Throw Test Error"
    }

    public func icon(centre: BookishHarness) -> Icon {
      Icon("exclamationmark.triangle")
    }

    public func help(centre: BookishHarness) -> String? {
      "Tests whether a command failure appears in the status bar."
    }

    public func perform(centre: BookishHarness) async throws {
      throw BookishTestCommandError.intentional
    }
  }
#endif
