// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import Foundation

/// Replaces the image used by the scanning workflow.
public struct SelectBookRecognitionImageCommand<Centre: BookishRecognitionProvider>: Command {
  /// The command does not return a value after replacing the image.
  public typealias ResultType = Void
  /// The image data selected by the user.
  public let imageData: Data?
  /// The stable command identifier.
  public let id = "recognition.select-image"

  /// Creates a command for the supplied image data.
  public init(imageData: Data?) {
    self.imageData = imageData
  }

  /// Disables image replacement while recognition is underway.
  public func availability(centre: Centre) -> CommandAvailability {
    centre.recognitionService.isRecognizing ? .disabled : .enabled
  }

  /// Replaces the recognition image and immediately identifies its books.
  public func perform(centre: Centre) async throws {
    centre.recognitionService.selectImage(data: imageData)
    await centre.recognitionService.identifyBooks()
  }
}
