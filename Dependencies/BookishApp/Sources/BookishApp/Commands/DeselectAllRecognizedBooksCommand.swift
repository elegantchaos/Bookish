// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Icons

/// Clears the selection in the scanning candidate list.
public struct DeselectAllRecognizedBooksCommand<Centre: BookishRecognitionProvider>: CommandWithUI {
  /// The command does not return a value after changing the selection.
  public typealias ResultType = Void

  /// The stable command identifier.
  public let id = "recognition.deselect-all-books"

  /// Creates the command.
  public init() {
  }

  /// Enables the command when at least one candidate is selected.
  public func availability(centre: Centre) -> CommandAvailability {
    centre.recognitionService.selectedCandidateIDs.isEmpty ? .disabled : .enabled
  }

  /// Returns the user-facing command name.
  public func name(centre _: Centre) -> String { "Deselect All" }

  /// Returns the command icon.
  public func icon(centre _: Centre) -> Icon { Icon("xmark.circle") }

  /// Explains the command's result.
  public func help(centre _: Centre) -> String? { "Clear the book-candidate selection." }

  /// Clears the selection through the recognition workflow.
  public func perform(centre: Centre) async throws {
    centre.recognitionService.deselectAllCandidates()
  }
}
