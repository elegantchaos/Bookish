// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import FoundationModels

/// Identifies books using Vision OCR followed by Apple's on-device Foundation Model.
///
/// Vision extracts visible spine and cover text before the language model produces structured
/// candidates. This keeps the recognition provider's image-data contract consistent across providers.
public struct OCRBookRecognitionProvider: BookRecognitionProvider {
  /// The stable identifier for the OCR recognition provider.
  public let id = BookRecognitionProviderID.ocrOnly

  /// The user-facing recognition provider name.
  public let label = "OCR"

  /// Explains the recognition provider's two-step process.
  public let description =
    "Books are identified using a combination of Apple Vision & Apple Intelligence."

  /// Creates an OCR-backed Foundation Models recognition provider.
  public init() {
  }

  /// Identifies books from text recognized in the supplied image.
  public func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate] {
    guard SystemLanguageModel.default.isAvailable else {
      throw BookRecognitionError.foundationModelsUnavailable
    }

    let recognizedText = try BookImageTextExtractor().recognizeText(in: imageData)
    guard !recognizedText.isEmpty else {
      throw BookRecognitionError.noReadableBookText
    }

    let session = LanguageModelSession(
      model: .default,
      instructions:
        "You identify books from OCR text. Return only books supported by the text. Do not invent titles, authors, editions, or ISBNs."
    )
    let response = try await session.respond(
      to: """
        Identify books from this OCR text. Include a confidence from zero to one for each candidate.

        \(recognizedText)
        """,
      generating: BookRecognitionResult.self
    )
    return response.content.candidates
  }
}
