// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import FoundationModels
import ImageIO
import Vision

/// Identifies books using Vision OCR followed by Apple's on-device Foundation Model.
///
/// The installed Foundation Models framework accepts text prompts, so Vision extracts the
/// visible spine and cover text before the model produces structured candidates. This keeps
/// the recognition service's image-data contract consistent with the OpenAI implementation.
public struct FoundationModelsBookRecognizer: BookRecognitionService {
  /// Identifies this service in the provider picker.
  public let provider: BookRecognitionProvider

  /// Creates an on-device Foundation Models recognizer.
  public init(provider: BookRecognitionProvider = .appleOnDevice) {
    self.provider = provider
  }

  /// Identifies books from text recognized in the supplied image.
  public func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate] {
    guard SystemLanguageModel.default.isAvailable else {
      throw BookRecognitionError.foundationModelsUnavailable
    }

    let recognizedText = try BookImageTextRecognizer().recognizeText(in: imageData)
    guard recognizedText.isEmpty == false else {
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
      generating: FoundationModelsBookRecognitionResult.self
    )
    return response.content.candidates.map {
      BookRecognitionCandidate(
        title: $0.title,
        authors: $0.authors,
        confidence: $0.confidence
      )
    }
  }
}

/// Reports that this build cannot yet create Apple's Private Cloud Compute model.
///
/// Private Cloud Compute is a newer beta API than the Foundation Models SDK used by this
/// project. Keeping this explicit provider prevents a silent fallback to either on-device
/// Apple Intelligence or OpenAI.
public struct UnavailablePrivateCloudComputeBookRecognizer: BookRecognitionService {
  /// Identifies this service in the provider picker.
  public let provider = BookRecognitionProvider.applePrivateCloudCompute

  /// Creates the explicit unavailable service.
  public init() {
  }

  /// Explains why this build cannot make the requested Private Cloud Compute call.
  public func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate] {
    throw BookRecognitionError.privateCloudComputeUnavailable
  }
}

/// Extracts the visible text that the on-device language model uses as input.
private struct BookImageTextRecognizer {
  /// Performs accurate, uncorrected text recognition on an image's first frame.
  func recognizeText(in imageData: Data) throws -> String {
    guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
      throw BookRecognitionError.noReadableBookText
    }

    let request = VNRecognizeTextRequest()
    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false
    let handler = VNImageRequestHandler(cgImage: image)
    try handler.perform([request])

    return (request.results ?? [])
      .compactMap { $0.topCandidates(1).first?.string }
      .joined(separator: "\n")
  }
}

/// The constrained Foundation Models response used for an OCR-derived identification.
@Generable(description: "Book identification candidates that are supported by supplied OCR text.")
private struct FoundationModelsBookRecognitionResult {
  /// Candidate books visible in the source text.
  var candidates: [FoundationModelsBookRecognitionCandidate]
}

/// A Foundation Models representation of one book candidate.
@Generable(description: "One book that can be identified from supplied OCR text.")
private struct FoundationModelsBookRecognitionCandidate {
  /// The book title.
  var title: String

  /// The book's authors, if visible in the OCR text.
  var authors: [String]

  /// The model's confidence from zero to one.
  var confidence: Double
}
