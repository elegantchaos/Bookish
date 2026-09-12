import Foundation
import Testing

@testable import BookishApp

struct BookRecognitionTests {
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
