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
    let fixture = RecordingRecognitionSession(responseData: responseData)
    defer { fixture.close() }
    let recognizer = OpenAIResponsesBookRecognizer(
      credentials: StaticBookRecognitionCredentials(apiKey: "test-key"),
      session: fixture.session
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
    let request = try #require(fixture.request)
    #expect(request.httpMethod == "POST")
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
    let fixture = RecordingRecognitionSession(responseData: Data())
    defer { fixture.close() }
    let recognizer = OpenAIResponsesBookRecognizer(
      credentials: StaticBookRecognitionCredentials(apiKey: nil),
      session: fixture.session
    )

    await #expect(throws: BookRecognitionError.self) {
      try await recognizer.identifyBooks(in: Data([0xFF, 0xD8, 0xFF]))
    }
    #expect(fixture.request == nil)
  }

  @Test
  func directImageRecognizersReportTheirAvailabilityRequirementBeforeMacOS27() async {
    guard #unavailable(macOS 27.0) else { return }

    #expect(OnDeviceBookRecognizer().isSupported == false)
    #expect(CloudComputeBookRecognizer().isSupported == false)

    await #expect(throws: BookRecognitionError.self) {
      try await OnDeviceBookRecognizer().identifyBooks(in: Data())
    }
    await #expect(throws: BookRecognitionError.self) {
      try await CloudComputeBookRecognizer().identifyBooks(in: Data())
    }
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
