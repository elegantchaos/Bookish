import BookishCapture
import Foundation
import Settings
import Testing

@testable import BookishApp

@MainActor
struct BookRecognitionTests {
  @Test
  func selectedRecognizerRestoresFromSettings() throws {
    let suiteName = "BookRecognitionTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let registry = BookRecognizerRegistry()
    registry.register(TestBookRecognizer(id: .fake))
    registry.register(TestBookRecognizer(id: .ocrOnly))

    defaults.set(.ocrOnly, forKey: .bookRecognizer)

    #expect(
      BookishRecognitionService.selectedRecognizerID(in: registry, settings: defaults) == .ocrOnly)
  }

  @Test
  func selectedRecognizerFallsBackWhenTheSettingsValueIsNotRegistered() throws {
    let suiteName = "BookRecognitionTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let registry = BookRecognizerRegistry()
    registry.register(TestBookRecognizer(id: .fake))

    defaults.set(.openAI, forKey: .bookRecognizer)

    #expect(
      BookishRecognitionService.selectedRecognizerID(in: registry, settings: defaults) == .fake
    )
  }

  @Test
  func selectedRecognizerFallsBackWhenTheSettingsValueIsUnavailable() throws {
    let suiteName = "BookRecognitionTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let registry = BookRecognizerRegistry()
    registry.register(TestBookRecognizer(id: .fake))
    registry.register(TestBookRecognizer(id: .openAI, isSupported: false))

    defaults.set(.openAI, forKey: .bookRecognizer)

    #expect(
      BookishRecognitionService.selectedRecognizerID(in: registry, settings: defaults) == .fake
    )
  }
}
