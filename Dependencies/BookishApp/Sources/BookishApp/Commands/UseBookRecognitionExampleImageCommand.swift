// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Icons

/// Selects Bookish's bundled recognition image.
public struct UseBookRecognitionExampleImageCommand<Centre: BookishRecognitionProvider>:
  CommandWithUI
{
  /// The command does not return a value after selecting the image.
  public typealias ResultType = Void
  /// The stable command identifier.
  public let id = "recognition.use-example-image"

  /// Creates the command.
  public init() {
  }

  /// Disables selection while recognition is underway.
  public func availability(centre: Centre) -> CommandAvailability {
    centre.recognitionService.isRecognizing ? .disabled : .enabled
  }

  /// Returns the user-facing command name.
  public func name(centre _: Centre) -> String { "Use Example Image" }
  /// Returns the command icon.
  public func icon(centre _: Centre) -> Icon { Icon("photo") }
  /// Explains the command's result.
  public func help(centre _: Centre) -> String? { "Select the bundled image for book recognition." }

  /// Selects the bundled image and immediately identifies its books.
  public func perform(centre: Centre) async throws {
    centre.recognitionService.selectCaptureGoodExample()
    await centre.recognitionService.identifyBooks()
  }
}
