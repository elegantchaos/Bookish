// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands

/// Selects a recognition provider and reruns recognition when an image is selected.
public struct SelectRecognizerCommand<Centre: BookishRecognitionProvider>: Command {
  /// The command does not return a value after selecting a provider.
  public typealias ResultType = Void

  /// The provider selected by the user.
  public let recognizer: String

  /// The stable command identifier.
  public let id = "recognition.select-provider"

  /// Creates a command for the selected provider.
  public init(provider: String) {
    self.recognizer = provider
  }

  /// Disables provider changes while recognition is underway.
  public func availability(centre: Centre) -> CommandAvailability {
    centre.recognitionService.isRecognizing ? .disabled : .enabled
  }

  /// Selects the provider through the recognition workflow.
  public func perform(centre: Centre) async throws {
    await centre.recognitionService.selectRecognizer(recognizer)
  }
}
