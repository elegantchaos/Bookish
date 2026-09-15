import BookishCapture
import Foundation
import Testing

@testable import BookishApp

@MainActor
struct BookRecognitionTests {
  @Test
  func selectedRecognizerPersistsAcrossPreferenceInstances() throws {
    let suiteName = "BookRecognitionTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let registry = BookRecognizerRegistry()
    registry.register(TestBookRecognizer(id: "example"))
    registry.register(TestBookRecognizer(id: "saved"))

    let selection = BookRecognitionMethodPreference(defaults: defaults)
    selection.save(recognizerID: "saved")
    let restoredSelection = BookRecognitionMethodPreference(defaults: defaults)

    #expect(restoredSelection.recognizerID(in: registry) == "saved")
  }
}

private struct TestBookRecognizer: BookRecognizer {
  let id: String
  let label: String
  let description: String

  init(id: String) {
    self.id = id
    label = id
    description = id
  }

  func identifyBooks(in _: Data) async throws -> [BookRecognitionCandidate] {
    []
  }
}
