// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import FoundationModels

/// Identifies books by passing an image directly to the on-device Foundation Model.
///
/// Direct image input remains separate from OCR so selecting On Device never changes the
/// image-processing path implicitly.
public struct OnDeviceBookRecognizer: BookRecognizer {
  /// The stable identifier for the direct-image recognizer.
  public let id = "com.elegantchaos.bookish.recognizer.direct"

  /// The user-facing recognizer name.
  public let label = "On Device"

  /// Explains the recognizer's direct-image processing path.
  public let description = "Apple Intelligence identifies books directly from the selected image."

  /// Creates the direct-image recognizer.
  public init() {}

  /// Identifies books directly from the supplied image on macOS and iOS 27 or later.
  public func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate] {
    guard #available(iOS 27.0, macOS 27.0, *) else {
      throw BookRecognitionError.directImageRecognitionUnavailable
    }
    let model = SystemLanguageModel.default
    guard model.isAvailable else {
      throw BookRecognitionError.foundationModelsUnavailable
    }
    return try await DirectImageBookRecognizer().identifyBooks(
      in: imageData,
      using: model
    )
  }
}
