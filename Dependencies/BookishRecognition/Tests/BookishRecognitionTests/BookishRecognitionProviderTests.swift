// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Testing

@testable import BookishRecognition

/// Verifies the package's public recognition-provider registry.
struct BookRecognitionProviderRegistryTests {
  @Test
  func defaultRecognitionProvidersCanBeLookedUpByIdentifier() {
    let registry = BookRecognitionProviderRegistry()
    registry.registerDefaultRecognitionProviders()

    for identifier in registry.recognitionProviderIDs {
      #expect(registry.recognitionProvider(for: identifier).id == identifier)
    }
    #expect(!registry.recognitionProviderIDs.contains(.openAI))
  }

  /// Allows the client to add, replace, and remove configured recognition providers at runtime.
  @Test
  func registryReconfiguresRecognitionProvidersByIdentifier() {
    let registry = BookRecognitionProviderRegistry()
    registry.register(FakeBookRecognitionProvider())
    registry.register(OpenAIResponsesBookRecognitionProvider(apiKey: "first"))
    registry.register(OpenAIResponsesBookRecognitionProvider(apiKey: "replacement"))

    registry.unregister(.openAI)

    #expect(registry.recognitionProviderIDs == [.fake])
  }

  @Test
  func fakeRecognitionProviderReturnsTheSameSampleCandidatesForEveryImage() async throws {
    let recognitionProvider = FakeBookRecognitionProvider()

    let emptyImageCandidates = try await recognitionProvider.identifyBooks(in: Data())
    let arbitraryImageCandidates = try await recognitionProvider.identifyBooks(
      in: Data([0xFF, 0xD8, 0xFF]))

    #expect(emptyImageCandidates == FakeBookRecognitionProvider.sampleCandidates)
    #expect(arbitraryImageCandidates == FakeBookRecognitionProvider.sampleCandidates)
  }

  @Test
  func openAIRecognitionProviderSendsAnImageRequestAndDecodesCandidates() async throws {
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
    let recognitionProvider = OpenAIResponsesBookRecognitionProvider(
      apiKey: "test-key",
      session: fixture.session
    )

    let candidates = try await recognitionProvider.identifyBooks(in: Data([0xFF, 0xD8, 0xFF]))

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
  func directImageRecognitionProvidersReportTheirAvailabilityRequirementBeforeMacOS27() async {
    guard #unavailable(macOS 27.0) else { return }

    #expect(!OnDeviceBookRecognitionProvider().isSupported)
    #expect(!CloudComputeBookRecognitionProvider().isSupported)

    await #expect(throws: BookRecognitionError.self) {
      try await OnDeviceBookRecognitionProvider().identifyBooks(in: Data())
    }
    await #expect(throws: BookRecognitionError.self) {
      try await CloudComputeBookRecognitionProvider().identifyBooks(in: Data())
    }
  }
}
