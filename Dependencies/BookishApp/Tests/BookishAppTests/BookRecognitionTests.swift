import BookishRecognition
import Foundation
import Settings
import Testing

@testable import BookishApp

@MainActor
struct BookRecognitionTests {
  @Test
  func selectedRecognitionProviderRestoresFromSettings() throws {
    let suiteName = "BookRecognitionTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let registry = BookRecognitionProviderRegistry()
    registry.register(TestBookRecognitionProvider(id: .fake))
    registry.register(TestBookRecognitionProvider(id: .ocrOnly))

    defaults.set(.ocrOnly, forKey: .bookRecognitionProvider)

    #expect(
      BookishRecognitionService.selectedRecognitionProviderID(in: registry, settings: defaults)
        == .ocrOnly)
  }

  @Test
  func selectedRecognitionProviderFallsBackWhenTheSettingsValueIsNotRegistered() throws {
    let suiteName = "BookRecognitionTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let registry = BookRecognitionProviderRegistry()
    registry.register(TestBookRecognitionProvider(id: .fake))

    defaults.set(.openAI, forKey: .bookRecognitionProvider)

    #expect(
      BookishRecognitionService.selectedRecognitionProviderID(in: registry, settings: defaults)
        == .fake
    )
  }

  @Test
  func selectedRecognitionProviderFallsBackWhenTheSettingsValueIsUnavailable() throws {
    let suiteName = "BookRecognitionTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defer { defaults.removePersistentDomain(forName: suiteName) }
    let registry = BookRecognitionProviderRegistry()
    registry.register(TestBookRecognitionProvider(id: .fake))
    registry.register(TestBookRecognitionProvider(id: .openAI, isSupported: false))

    defaults.set(.openAI, forKey: .bookRecognitionProvider)

    #expect(
      BookishRecognitionService.selectedRecognitionProviderID(in: registry, settings: defaults)
        == .fake
    )
  }
}
