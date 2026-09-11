// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Icons

/// Selects every candidate currently shown in the scanning list.
public struct SelectAllRecognizedBooksCommand<Centre: BookishRecognitionProvider>: CommandWithUI {
  /// The command does not return a value after changing the selection.
  public typealias ResultType = Void

  /// The stable command identifier.
  public let id = "recognition.select-all-books"

  /// Creates the command.
  public init() {
  }

  /// Enables the command when at least one candidate is not selected.
  public func availability(centre: Centre) -> CommandAvailability {
    let recognition = centre.recognitionService
    return recognition.candidates.isEmpty == false
      && recognition.selectedCandidateIDs.count < recognition.candidates.count
      ? .enabled : .disabled
  }

  /// Returns the user-facing command name.
  public func name(centre _: Centre) -> String { "Select All" }

  /// Returns the command icon.
  public func icon(centre _: Centre) -> Icon { Icon("checkmark.circle") }

  /// Explains the command's result.
  public func help(centre _: Centre) -> String? { "Select every book candidate." }

  /// Selects all candidates through the recognition workflow.
  public func perform(centre: Centre) async throws {
    centre.recognitionService.selectAllCandidates()
  }
}
