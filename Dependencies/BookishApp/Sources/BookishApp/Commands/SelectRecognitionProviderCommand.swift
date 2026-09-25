// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecognition
import Commands
import CommandsUI
import Icons

/// Selects the recognition provider used by the next capture.
public struct SelectRecognitionProviderCommand<Centre: BookishRecognitionService.Provider>:
  CommandWithUI
{
  /// The command does not return a value after selecting a provider.
  public typealias ResultType = Void

  /// The provider selected by the user.
  public let recognitionProvider: BookRecognitionProviderID

  /// The stable command identifier.
  public let id = "recognition.select-provider"

  /// Creates a command for the selected provider.
  public init(_ recognitionProvider: BookRecognitionProviderID) {
    self.recognitionProvider = recognitionProvider
  }

  /// Enables selection only for a recognition provider that can run on this device.
  public func availability(centre: Centre) -> CommandAvailability {
    !centre.recognitionService.isRecognizing
      && centre.recognitionService.isRecognitionProviderSupported(recognitionProvider)
      ? .enabled : .disabled
  }

  /// Returns the user-facing command name.
  public func name(centre _: Centre) -> String { "Select Recognition Provider" }

  /// Returns the standard recognition provider-selection icon.
  public func icon(centre _: Centre) -> Icon { Icon("brain") }

  /// Explains that the recognition provider will be selected without starting recognition.
  public func help(centre _: Centre) -> String? {
    "Use this recognition provider when you capture books."
  }

  /// Selects the provider through the recognition workflow without starting recognition.
  public func perform(centre: Centre) async throws {
    centre.recognitionService.selectRecognitionProvider(recognitionProvider)
  }
}
