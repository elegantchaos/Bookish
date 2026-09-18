// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Icons

/// Identifies books in the selected image using the selected recognition provider.
public struct CaptureBooksCommand<Centre: BookishRecognitionProvider>: CommandWithUI {
  /// The command does not return a value after starting recognition.
  public typealias ResultType = Void

  /// The stable command identifier.
  public let id = "recognition.capture-books"

  /// Creates the command.
  public init() {
  }

  /// Enables capture only when a selected image can be processed.
  public func availability(centre: Centre) -> CommandAvailability {
    let recognition = centre.recognitionService
    return recognition.hasImage && recognition.isCurrentRecognitionProviderSupported
      && recognition.isRecognizing == false
      ? .enabled : .disabled
  }

  /// Returns the user-facing command name.
  public func name(centre _: Centre) -> String { "Capture Books" }

  /// Returns the command icon.
  public func icon(centre _: Centre) -> Icon { Icon("text.viewfinder") }

  /// Explains that the selected image will be identified.
  public func help(centre _: Centre) -> String? {
    "Identify books in the selected image."
  }

  /// Identifies books in the selected image.
  public func perform(centre: Centre) async throws {
    await centre.recognitionService.identifyBooks()
  }
}
