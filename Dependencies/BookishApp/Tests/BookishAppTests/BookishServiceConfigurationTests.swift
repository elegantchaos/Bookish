// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup
import BookishRecognition
import Testing

@testable import BookishApp

/// Verifies the application's composition of credential-free and configured providers.
struct BookishServiceConfigurationTests {
  /// Adds optional providers only when the application has supplied their credentials.
  @Test
  func configuredCredentialsEnableTheirProviders() throws {
    let configuration = BookishServiceConfiguration(
      googleBooksAPIKey: "google-key",
      openAIAPIKey: "openai-key"
    )

    let googleBooks = try #require(configuration.lookupProviders.first { $0.id == .googleBooks })
    #expect(googleBooks.isSupported)
    #expect(configuration.recognitionProviders.map(\.id).contains(.openAI))
  }

  /// Includes credential-backed providers as unavailable when the application has no credentials.
  @Test
  func emptyCredentialsDisableTheirProviders() throws {
    let configuration = BookishServiceConfiguration()

    let googleBooks = try #require(configuration.lookupProviders.first { $0.id == .googleBooks })
    #expect(googleBooks.isSupported == false)
    #expect(configuration.recognitionProviders.map(\.id).contains(.openAI) == false)
  }

  /// Replaces optional services when the application's credential state changes.
  @Test
  @MainActor
  func engineReconfiguresOptionalServices() async throws {
    let engine = BookishEngine()

    await engine.configureServices(
      BookishServiceConfiguration(googleBooksAPIKey: "google-key", openAIAPIKey: "openai-key")
    )
    let configuredGoogleBooks = try #require(
      engine.lookup.providers.first { $0.id == .googleBooks })
    #expect(configuredGoogleBooks.isSupported)
    #expect(engine.recognition.recognitionProviderIDs.contains(.openAI))

    await engine.configureServices(BookishServiceConfiguration())
    let unconfiguredGoogleBooks = try #require(
      engine.lookup.providers.first { $0.id == .googleBooks })
    #expect(unconfiguredGoogleBooks.isSupported == false)
    #expect(engine.recognition.recognitionProviderIDs.contains(.openAI) == false)
  }
}
