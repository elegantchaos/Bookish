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
    registry.register(TestBookRecognizer(id: "example"))
    registry.register(TestBookRecognizer(id: "saved"))

    defaults.set("saved", forKey: .bookRecognitionProvider)

    #expect(
      BookishRecognitionService.selectedRecognizerID(in: registry, settings: defaults) == "saved")
  }

  @Test
  func selectedRecognizerFallsBackWhenTheSettingsValueIsNotRegistered() throws {
    let suiteName = "BookRecognitionTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let registry = BookRecognizerRegistry()
    registry.register(TestBookRecognizer(id: "fallback"))

    defaults.set("unregistered", forKey: .bookRecognitionProvider)

    #expect(
      BookishRecognitionService.selectedRecognizerID(in: registry, settings: defaults) == "fallback"
    )
  }

  @Test
  func selectedRecognizerFallsBackWhenTheSettingsValueIsUnavailable() throws {
    let suiteName = "BookRecognitionTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let registry = BookRecognizerRegistry()
    registry.register(TestBookRecognizer(id: "fallback"))
    registry.register(TestBookRecognizer(id: "unavailable", isSupported: false))

    defaults.set("unavailable", forKey: .bookRecognitionProvider)

    #expect(
      BookishRecognitionService.selectedRecognizerID(in: registry, settings: defaults) == "fallback"
    )
  }
}
