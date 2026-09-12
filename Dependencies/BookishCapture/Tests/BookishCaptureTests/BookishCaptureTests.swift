// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Testing

@testable import BookishCapture

/// Verifies the package's public recognition-provider registry.
struct BookRecognizerRegistryTests {
  @Test
  func defaultRecognizersCanBeLookedUpByIdentifier() {
    let registry = BookRecognizerRegistry()
    registry.registerDefaultRecognizers()

    for identifier in registry.recognizerIDs {
      #expect(registry.recognizer(for: identifier).id == identifier)
    }
  }

  @Test
  func fakeRecognizerReturnsTheSameSampleCandidatesForEveryImage() async throws {
    let recognizer = FakeBookRecognizer()

    let emptyImageCandidates = try await recognizer.identifyBooks(in: Data())
    let arbitraryImageCandidates = try await recognizer.identifyBooks(in: Data([0xFF, 0xD8, 0xFF]))

    #expect(emptyImageCandidates == FakeBookRecognizer.sampleCandidates)
    #expect(arbitraryImageCandidates == FakeBookRecognizer.sampleCandidates)
  }

  @Test
  func openAIRecognizerSendsAnImageRequestAndDecodesCandidates() async throws {
    let responseData = Data(
      """
      {
        "output": [{
          "content": [{
            "type": "output_text",
            "text": "{\\\"candidates\\\":[{\\\"title\\\":\\\"Refactoring\\\",\\\"authors\\\":[\\\"Martin Fowler\\\"],\\\"confidence\\\":0.98}]}"
          }]
        }]
      }
      """.utf8)
    let transport = RecordingBookRecognitionTransport(responseData: responseData)
    let recognizer = OpenAIResponsesBookRecognizer(
      credentials: StaticBookRecognitionCredentials(apiKey: "test-key"),
      transport: transport
    )

    let candidates = try await recognizer.identifyBooks(in: Data([0xFF, 0xD8, 0xFF]))

    #expect(
      candidates == [
        BookRecognitionCandidate(
          title: "Refactoring",
          authors: ["Martin Fowler"],
          confidence: 0.98
        )
      ])
    let request = try #require(await transport.request)
    #expect(request.url == URL(string: "https://api.openai.com/v1/responses"))
    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
    #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
    let body = try #require(request.httpBody)
    let requestJSON = try JSONSerialization.jsonObject(with: body) as? [String: Any]
    #expect(requestJSON?["model"] as? String == "gpt-4.1-mini")
    #expect(requestJSON?["store"] as? Bool == false)
    let input = try #require(requestJSON?["input"] as? [[String: Any]])
    let content = try #require(input.first?["content"] as? [[String: Any]])
    let image = try #require(content.first(where: { $0["type"] as? String == "input_image" }))
    #expect(image["image_url"] as? String == "data:image/jpeg;base64,/9j/")
  }

  @Test
  func openAIRecognizerDoesNotSendARequestWithoutCredentials() async {
    let transport = RecordingBookRecognitionTransport(responseData: Data())
    let recognizer = OpenAIResponsesBookRecognizer(
      credentials: StaticBookRecognitionCredentials(apiKey: nil),
      transport: transport
    )

    await #expect(throws: BookRecognitionError.self) {
      try await recognizer.identifyBooks(in: Data([0xFF, 0xD8, 0xFF]))
    }
    #expect(await transport.request == nil)
  }
}

/// Provides a fixed API key for recognizer tests.
private struct StaticBookRecognitionCredentials: BookRecognitionCredentials {
  /// The key returned to the recognizer.
  let apiKey: String?

  /// Returns the fixed API key.
  func openAIAPIKey() throws -> String? {
    apiKey
  }
}

/// Records the request sent by a recognizer and returns fixed response data.
private actor RecordingBookRecognitionTransport: BookRecognitionTransport {
  /// The response returned for every request.
  let responseData: Data

  /// The most recent request received by the transport.
  private(set) var request: URLRequest?

  /// Creates a transport that returns fixed response data.
  init(responseData: Data) {
    self.responseData = responseData
  }

  /// Records a request and returns its fixed successful response.
  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    self.request = request
    let url = try #require(request.url)
    let response = try #require(
      HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)
    )
    return (responseData, response)
  }
}
