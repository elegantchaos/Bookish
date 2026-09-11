import Foundation
import Testing

@testable import BookishApp

struct BookRecognitionTests {
  @Test
  func defaultFactoryCreatesTheRequestedRecognitionService() {
    let factory = DefaultBookRecognitionServiceFactory()

    #expect(
      BookRecognitionProvider.allCases == [
        .fake, .ocr, .openAI, .appleOnDevice, .applePrivateCloudCompute,
      ])
    #expect(factory.service(for: .fake).provider == .fake)
    #expect(factory.service(for: .ocr).provider == .ocr)
    #expect(factory.service(for: .openAI).provider == .openAI)
    #expect(factory.service(for: .appleOnDevice).provider == .appleOnDevice)
    #expect(factory.service(for: .applePrivateCloudCompute).provider == .applePrivateCloudCompute)
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
  func recognizerReportsAMissingKeychainCredentialBeforeMakingARequest() async {
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

  @Test
  @MainActor
  func viewModelSelectsTheBundledCaptureGoodExampleImage() {
    let recognition = BookRecognitionViewModel()

    recognition.selectCaptureGoodExample()

    #expect(recognition.imageData?.isEmpty == false)
    #expect(recognition.error == nil)
  }

  @Test
  @MainActor
  func addingSelectedCandidatesPersistsAndRemovesOnlyTheSelection() async throws {
    let selected = BookRecognitionCandidate(
      title: "Refactoring",
      authors: ["Martin Fowler"],
      confidence: 0.98
    )
    let unselected = BookRecognitionCandidate(
      title: "Domain-Driven Design",
      authors: ["Eric Evans"],
      confidence: 0.95
    )
    let recognizer = StaticBookRecognitionService(candidates: [selected, unselected])
    let recordAdder = RecordingBookRecognitionRecordAdder()
    let recognition = BookRecognitionViewModel(
      serviceFactory: StaticBookRecognitionServiceFactory(service: recognizer),
      recordAdder: recordAdder
    )

    recognition.selectImage(data: Data([0xFF]))
    await recognition.identifyBooks()
    recognition.selectedCandidateIDs = [selected.id]
    try await recognition.addSelectedBooks()

    #expect(recordAdder.addedCandidates == [selected])
    #expect(recognition.candidates == [unselected])
    #expect(recognition.selectedCandidateIDs.isEmpty)
  }

  @Test
  @MainActor
  func selectingAndDeselectingAllCandidatesUpdatesTheSelection() async {
    let candidates = [
      BookRecognitionCandidate(title: "Refactoring", authors: [], confidence: 0.98),
      BookRecognitionCandidate(title: "Domain-Driven Design", authors: [], confidence: 0.95),
    ]
    let recognition = BookRecognitionViewModel(
      serviceFactory: StaticBookRecognitionServiceFactory(
        service: StaticBookRecognitionService(candidates: candidates)),
      recordAdder: RecordingBookRecognitionRecordAdder()
    )

    recognition.selectImage(data: Data([0xFF]))
    await recognition.identifyBooks()
    recognition.selectAllCandidates()

    #expect(recognition.selectedCandidateIDs == Set(candidates.map(\.id)))

    recognition.deselectAllCandidates()

    #expect(recognition.selectedCandidateIDs.isEmpty)
  }
}

@MainActor
private final class RecordingBookRecognitionRecordAdder: BookRecognitionRecordAdding {
  let canAddBooks = true
  private(set) var addedCandidates: [BookRecognitionCandidate] = []

  func addBooks(from candidates: [BookRecognitionCandidate]) async throws {
    addedCandidates.append(contentsOf: candidates)
  }
}

private struct StaticBookRecognitionServiceFactory: BookRecognitionServiceFactory {
  let service: any BookRecognitionService

  func service(for _: BookRecognitionProvider) -> any BookRecognitionService {
    service
  }
}

private struct StaticBookRecognitionService: BookRecognitionService {
  let provider = BookRecognitionProvider.openAI
  let candidates: [BookRecognitionCandidate]

  func identifyBooks(in _: Data) async throws -> [BookRecognitionCandidate] {
    candidates
  }
}

private struct StaticBookRecognitionCredentials: BookRecognitionCredentials {
  let apiKey: String?

  func openAIAPIKey() throws -> String? {
    apiKey
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
