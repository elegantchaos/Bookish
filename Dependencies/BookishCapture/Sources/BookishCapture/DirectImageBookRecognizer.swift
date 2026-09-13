// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import FoundationModels

/// Performs book recognition by attaching the supplied image directly to a language-model prompt.
@available(iOS 27.0, macOS 27.0, *)
struct DirectImageBookRecognizer {
  /// Identifies books with the supplied language model.
  func identifyBooks(
    in imageData: Data,
    using model: some LanguageModel
  ) async throws -> [BookRecognitionCandidate] {
    let session = LanguageModelSession(
      model: model,
      instructions:
        "You identify books from supplied images. Return only books supported by visible evidence. Do not invent titles, authors, editions, or ISBNs."
    )
    let image = try BookImageLoader().image(from: imageData)
    let response = try await session.respond(generating: BookRecognitionResult.self) {
      "Identify every clearly visible book in this image. Include a confidence from zero to one for each candidate."
      Attachment(image)
    }
    return response.content.candidates
  }
}
