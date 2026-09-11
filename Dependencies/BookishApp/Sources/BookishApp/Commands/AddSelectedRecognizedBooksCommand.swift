// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Icons

/// Adds the selected recognition candidates to the catalogue.
public struct AddSelectedRecognizedBooksCommand<Centre: BookishRecognitionProvider>: CommandWithUI {
  /// The command does not return a value after adding candidates.
  public typealias ResultType = Void

  /// The stable command identifier.
  public let id = "recognition.add-selected-books"

  /// Creates the command.
  public init() {
  }

  /// Enables the command only when selected candidates can be persisted.
  public func availability(centre: Centre) -> CommandAvailability {
    centre.recognitionService.canAddBooks
      && centre.recognitionService.selectedCandidateIDs.isEmpty == false ? .enabled : .disabled
  }

  /// Returns the user-facing command name for the current selection.
  public func name(centre: Centre) -> String {
    addsAllCandidates(centre: centre) ? "Add All" : "Add Selected"
  }

  /// Returns the command icon.
  public func icon(centre _: Centre) -> Icon {
    Icon("plus")
  }

  /// Explains the command's result for the current selection.
  public func help(centre: Centre) -> String? {
    addsAllCandidates(centre: centre)
      ? "Add every book candidate to the catalogue."
      : "Add the selected book candidates to the catalogue."
  }

  /// Adds selected candidates through the recognition workflow.
  public func perform(centre: Centre) async throws {
    try await centre.recognitionService.addSelectedBooks()
  }

  /// Returns whether the current selection includes every visible candidate.
  private func addsAllCandidates(centre: Centre) -> Bool {
    let recognition = centre.recognitionService
    return recognition.candidates.isEmpty == false
      && recognition.selectedCandidateIDs == Set(recognition.candidates.map(\.id))
  }
}
