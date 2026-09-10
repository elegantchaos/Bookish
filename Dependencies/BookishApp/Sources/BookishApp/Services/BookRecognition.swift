// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Codex on 09/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Observation

/// A possible identification of a book visible in an image.
public struct BookRecognitionCandidate: Codable, Equatable, Identifiable, Sendable {
  /// A stable identifier for display while the recognition result is in memory.
  public var id: String { "\(title)|\(authors.joined(separator: ","))" }

  /// The title read from the book or inferred from its visible cover or spine.
  public let title: String

  /// The authors identified for the book.
  public let authors: [String]

  /// The model's self-reported confidence from zero to one.
  public let confidence: Double

  /// Creates a book-recognition candidate.
  public init(title: String, authors: [String], confidence: Double) {
    self.title = title
    self.authors = authors
    self.confidence = confidence
  }
}

/// Identifies books from image data.
public protocol BookRecognitionService: Sendable {
  /// The provider represented by this service.
  var provider: BookRecognitionProvider { get }

  /// Identifies the books shown in an image.
  func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate]
}

/// The AI provider used to identify books in a selected image.
public enum BookRecognitionProvider: String, CaseIterable, Identifiable, Sendable {
  /// Sends the image to the OpenAI Responses API.
  case openAI

  /// Uses Vision text recognition and Apple's on-device Foundation Model.
  case appleOnDevice

  /// Reserves Vision text and Apple's Private Cloud Compute model for a newer SDK.
  case applePrivateCloudCompute

  /// Uses the provider identifier for SwiftUI selection.
  public var id: Self { self }

  /// The user-facing provider name.
  public var title: String {
    switch self {
    case .openAI:
      "OpenAI"
    case .appleOnDevice:
      "Apple On-Device"
    case .applePrivateCloudCompute:
      "Apple Private Cloud Compute"
    }
  }
}

/// Creates an AI service for a selected book-recognition provider.
public protocol BookRecognitionServiceFactory: Sendable {
  /// Creates the service represented by the requested provider.
  func service(for provider: BookRecognitionProvider) -> any BookRecognitionService
}

/// Creates Bookish's currently supported AI recognition services.
public struct DefaultBookRecognitionServiceFactory: BookRecognitionServiceFactory {
  /// Creates a factory that obtains the OpenAI key from the launch environment.
  public init() {
  }

  /// Creates the service for a user-selected provider.
  public func service(for provider: BookRecognitionProvider) -> any BookRecognitionService {
    switch provider {
    case .openAI:
      OpenAIResponsesBookRecognizer()
    case .appleOnDevice:
      FoundationModelsBookRecognizer(provider: provider)
    case .applePrivateCloudCompute:
      UnavailablePrivateCloudComputeBookRecognizer()
    }
  }
}

/// Performs the HTTP request required by a book recognizer.
public protocol BookRecognitionTransport: Sendable {
  /// Loads the data for a URL request.
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: BookRecognitionTransport {
}

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

  /// The installed Foundation Models SDK does not provide Private Cloud Compute yet.
  case privateCloudComputeUnavailable

  public var errorDescription: String? {
    switch self {
    case .missingAPIKey:
      "Set OPENAI_API_KEY in the app launch environment before identifying books."
    case .serverError(_, let message):
      message
    case .invalidResponse:
      "OpenAI returned an unreadable book-recognition response."
    case .noReadableBookText:
      "No readable book text was found in the selected image."
    case .foundationModelsUnavailable:
      "Apple Intelligence is unavailable or still preparing on this device."
    case .privateCloudComputeUnavailable:
      "Private Cloud Compute requires a newer Foundation Models SDK and its Apple entitlement."
    }
  }
}

/// Sends images to the OpenAI Responses API and decodes book-identification candidates.
public struct OpenAIResponsesBookRecognizer: BookRecognitionService {
  /// Identifies this service in the provider picker.
  public let provider = BookRecognitionProvider.openAI

  private let apiKey: String
  private let model: String
  private let transport: any BookRecognitionTransport

  /// Creates a recognizer using the launch environment's API key.
  public init(
    apiKey: String = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "",
    model: String = "gpt-4.1-mini",
    transport: any BookRecognitionTransport = URLSession.shared
  ) {
    self.apiKey = apiKey
    self.model = model
    self.transport = transport
  }

  /// Identifies clearly visible books without using external catalogue services.
  public func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate] {
    guard apiKey.isEmpty == false else {
      throw BookRecognitionError.missingAPIKey
    }

    var request = URLRequest(url: URL(string: "https://api.openai.com/v1/responses")!)
    request.httpMethod = "POST"
    request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(
      withJSONObject: requestBody(for: imageData),
      options: []
    )

    let (data, response) = try await transport.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw BookRecognitionError.invalidResponse
    }
    guard (200...299).contains(httpResponse.statusCode) else {
      throw BookRecognitionError.serverError(
        statusCode: httpResponse.statusCode,
        message: apiErrorMessage(from: data)
          ?? "OpenAI request failed (HTTP \(httpResponse.statusCode))."
      )
    }

    let responseBody = try JSONDecoder().decode(ResponsesResponse.self, from: data)
    guard let outputText = responseBody.outputText,
      let resultData = outputText.data(using: .utf8)
    else {
      throw BookRecognitionError.invalidResponse
    }
    return try JSONDecoder().decode(BookRecognitionResult.self, from: resultData).candidates
  }

  private func requestBody(for imageData: Data) -> [String: Any] {
    let encodedImage = imageData.base64EncodedString()
    return [
      "model": model,
      "store": false,
      "input": [
        [
          "role": "user",
          "content": [
            [
              "type": "input_text",
              "text":
                "Identify every clearly visible book in this image. Return only books you can identify from visible evidence. Do not invent titles, authors, editions, or ISBNs. Use JSON matching the supplied schema.",
            ],
            [
              "type": "input_image",
              "image_url": "data:image/jpeg;base64,\(encodedImage)",
              "detail": "high",
            ],
          ],
        ]
      ],
      "text": [
        "format": [
          "type": "json_schema",
          "name": "book_candidates",
          "strict": true,
          "schema": [
            "type": "object",
            "additionalProperties": false,
            "properties": [
              "candidates": [
                "type": "array",
                "items": [
                  "type": "object",
                  "additionalProperties": false,
                  "properties": [
                    "title": ["type": "string"],
                    "authors": ["type": "array", "items": ["type": "string"]],
                    "confidence": ["type": "number"],
                  ],
                  "required": ["title", "authors", "confidence"],
                ],
              ]
            ],
            "required": ["candidates"],
          ],
        ]
      ],
    ]
  }

  private func apiErrorMessage(from data: Data) -> String? {
    try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data).error.message
  }
}

/// Observable state for the first image-recognition workflow.
@MainActor
@Observable
public final class BookRecognitionViewModel {
  /// The provider used by the next recognition request.
  public var provider: BookRecognitionProvider

  /// The data selected by the user for recognition.
  public private(set) var imageData: Data?

  /// Candidate books returned by the recognizer.
  public private(set) var candidates: [BookRecognitionCandidate]

  /// A recognition error suitable for display.
  public private(set) var error: (any Error)?

  /// Whether a request is currently underway.
  public private(set) var isRecognizing: Bool

  @ObservationIgnored private let serviceFactory: any BookRecognitionServiceFactory

  /// Creates state backed by a recognition-service factory.
  public init(
    provider: BookRecognitionProvider = .openAI,
    serviceFactory: any BookRecognitionServiceFactory = DefaultBookRecognitionServiceFactory()
  ) {
    self.provider = provider
    self.serviceFactory = serviceFactory
    imageData = nil
    candidates = []
    error = nil
    isRecognizing = false
  }

  /// Replaces the selected image and clears the preceding result.
  public func selectImage(data: Data?) {
    imageData = data
    candidates = []
    error = nil
  }

  /// Requests identifications for the selected image.
  public func identifyBooks() async {
    guard let imageData else { return }
    isRecognizing = true
    error = nil
    defer { isRecognizing = false }

    do {
      candidates = try await serviceFactory.service(for: provider).identifyBooks(in: imageData)
    } catch {
      self.error = error
    }
  }
}

private struct ResponsesResponse: Decodable {
  let output: [OutputItem]
  let rawOutputText: String?

  var outputText: String? {
    output.lazy
      .flatMap(\.content)
      .first(where: { $0.type == "output_text" })?
      .text ?? rawOutputText
  }

  enum CodingKeys: String, CodingKey {
    case output
    case rawOutputText = "output_text"
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    output = try container.decodeIfPresent([OutputItem].self, forKey: .output) ?? []
    rawOutputText = try container.decodeIfPresent(String.self, forKey: .rawOutputText)
  }

  struct OutputItem: Decodable {
    let content: [OutputContent]
  }

  struct OutputContent: Decodable {
    let type: String
    let text: String?
  }
}

private struct BookRecognitionResult: Decodable {
  let candidates: [BookRecognitionCandidate]
}

private struct OpenAIErrorResponse: Decodable {
  let error: ErrorDetail

  struct ErrorDetail: Decodable {
    let message: String
  }
}
