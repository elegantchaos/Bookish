// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Errors surfaced by the Responses API recognizer.
public enum BookRecognitionError: LocalizedError {
  /// The app was launched without an API key.
  case missingAPIKey

  /// The API returned a non-successful HTTP status.
  case serverError(statusCode: Int, message: String)

  /// The API response did not contain the requested structured result.
  case invalidResponse

  /// Vision did not find text suitable for book identification.
  case noReadableBookText

  /// Apple Intelligence is not ready on the current device.
  case foundationModelsUnavailable

  /// The installed Foundation Models SDK cannot pass images directly to the model.
  case directImageRecognitionUnavailable

  /// The installed Foundation Models SDK does not provide Private Cloud Compute yet.
  case privateCloudComputeUnavailable

  /// The bundled recognition example image could not be read.
  case captureGoodExampleUnavailable

  public var errorDescription: String? {
    switch self {
    case .missingAPIKey:
      "Store an OpenAI API key in Keychain for account openai-api-key on api.openai.com."
    case .serverError(_, let message):
      message
    case .invalidResponse:
      "OpenAI returned an unreadable book-recognition response."
    case .noReadableBookText:
      "No readable book text was found in the selected image."
    case .foundationModelsUnavailable:
      "Apple Intelligence is unavailable or still preparing on this device."
    case .directImageRecognitionUnavailable:
      "Direct image recognition requires a newer Foundation Models SDK. Use OCR in this build."
    case .privateCloudComputeUnavailable:
      "Private Cloud Compute requires a newer Foundation Models SDK and its Apple entitlement."
    case .captureGoodExampleUnavailable:
      "The bundled CaptureGoodExample image could not be loaded."
    }
  }
}
