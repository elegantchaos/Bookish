// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Sends images to the OpenAI Responses API and decodes book-identification candidates.
public struct OpenAIResponsesBookRecognizer: BookRecognizer {
  public let id = "com.bookish.elegantchao.recognizer.openai"
  public let label = "OpenAI"
  public let description: String = "The selected image is sent to OpenAI only when you choose Identify Books."
  
  private let credentials: any BookRecognitionCredentials
  private let model: String

  /// Creates a recognizer using a Keychain-backed credential provider by default.
  public init(
    credentials: any BookRecognitionCredentials = KeychainBookRecognitionCredentials(),
    model: String = "gpt-4.1-mini",
  ) {
    self.credentials = credentials
    self.model = model
  }

  /// Identifies clearly visible books without using external catalogue services.
  public func identifyBooks(in imageData: Data) async throws -> [BookRecognitionCandidate] {
    guard
      let apiKey = try credentials.openAIAPIKey()?.trimmingCharacters(in: .whitespacesAndNewlines),
      apiKey.isEmpty == false
    else {
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

    let (data, response) = try await URLSession.shared.data(for: request)
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

    let responseBody = try JSONDecoder().decode(OpenAIResponsesResponse.self, from: data)
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

private struct OpenAIErrorResponse: Decodable {
  let error: ErrorDetail

  struct ErrorDetail: Decodable {
    let message: String
  }
}
