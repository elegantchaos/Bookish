import Foundation
import Testing

@testable import BookishApp

struct BookRecognitionTests {
  @Test
  func defaultFactoryCreatesTheRequestedRecognitionService() {
    let factory = DefaultBookRecognitionServiceFactory()

    #expect(factory.service(for: .openAI).provider == .openAI)
    #expect(factory.service(for: .appleOnDevice).provider == .appleOnDevice)
    #expect(factory.service(for: .applePrivateCloudCompute).provider == .applePrivateCloudCompute)
  }

  @Test
  func recognizerSendsImageAsAResponsesAPIVisionRequestAndDecodesCandidates() async throws {
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
      apiKey: "test-key",
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
}

private actor RecordingBookRecognitionTransport: BookRecognitionTransport {
  let responseData: Data
  private(set) var request: URLRequest?

  init(responseData: Data) {
    self.responseData = responseData
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    self.request = request
    let response = HTTPURLResponse(
      url: try #require(request.url),
      statusCode: 200,
      httpVersion: nil,
      headerFields: nil
    )!
    return (responseData, response)
  }
}
