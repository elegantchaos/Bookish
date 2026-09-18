// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCapture
import BookishLookup
import Testing

@testable import BookishApp

/// Verifies the application's composition of credential-free and configured providers.
struct BookishServiceConfigurationTests {
  /// Adds optional providers only when the application has supplied their credentials.
  @Test
  func configuredCredentialsEnableTheirProviders() {
    let configuration = BookishServiceConfiguration(
      googleBooksAPIKey: "google-key",
      openAIAPIKey: "openai-key"
    )

    #expect(configuration.lookupProviders.map(\.id).contains("google-books"))
    #expect(configuration.recognizers.map(\.id).contains(.openAI))
  }

  /// Omits optional providers when the application has no credentials to supply.
  @Test
  func emptyCredentialsOmitTheirProviders() {
    let configuration = BookishServiceConfiguration()

    #expect(configuration.lookupProviders.map(\.id).contains("google-books") == false)
    #expect(configuration.recognizers.map(\.id).contains(.openAI) == false)
  }

  /// Replaces optional services when the application's credential state changes.
  @Test
  @MainActor
  func engineReconfiguresOptionalServices() async {
    let engine = BookishEngine()

    await engine.configureServices(
      BookishServiceConfiguration(googleBooksAPIKey: "google-key", openAIAPIKey: "openai-key")
    )
    #expect(engine.lookup.providers.map(\.id).contains("google-books"))
    #expect(engine.recognition.recognizerIDs.contains(.openAI))

    await engine.configureServices(BookishServiceConfiguration())
    #expect(engine.lookup.providers.map(\.id).contains("google-books") == false)
    #expect(engine.recognition.recognizerIDs.contains(.openAI) == false)
  }
}
