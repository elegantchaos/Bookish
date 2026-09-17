// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCapture
import Commands
import CommandsUI
import Icons

/// Selects the recognizer used by the next capture.
public struct SelectRecognizerCommand<Centre: BookishRecognitionProvider>: CommandWithUI {
  /// The command does not return a value after selecting a provider.
  public typealias ResultType = Void

  /// The provider selected by the user.
  public let recognizer: BookRecognizerID

  /// The stable command identifier.
  public let id = "recognition.select-provider"

  /// Creates a command for the selected provider.
  public init(_ recognizer: BookRecognizerID) {
    self.recognizer = recognizer
  }

  /// Enables selection only for a recognizer that can run on this device.
  public func availability(centre: Centre) -> CommandAvailability {
    !centre.recognitionService.isRecognizing
      && centre.recognitionService.isRecognizerSupported(recognizer)
      ? .enabled : .disabled
  }

  /// Returns the user-facing command name.
  public func name(centre _: Centre) -> String { "Select Recognizer" }

  /// Returns the standard recognizer-selection icon.
  public func icon(centre _: Centre) -> Icon { Icon("brain") }

  /// Explains that the recognizer will be selected without starting recognition.
  public func help(centre _: Centre) -> String? {
    "Use this recognizer when you capture books."
  }

  /// Selects the provider through the recognition workflow without starting recognition.
  public func perform(centre: Centre) async throws {
    await centre.recognitionService.selectRecognizer(recognizer)
  }
}
