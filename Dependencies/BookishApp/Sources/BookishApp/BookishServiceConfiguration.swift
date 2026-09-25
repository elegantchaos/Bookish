// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishLookup
import BookishRecognition
import Keychain

/// Holds application-owned configuration for optional external book services.
///
/// This type is the boundary between credential storage and reusable provider
/// packages. It reads the Keychain only in the application, then constructs
/// configured adapters with the resulting values.
public struct BookishServiceConfiguration {
  /// The account name used to store Bookish's Google Books API key.
  static let googleBooksAccount = "google-books-api-key"

  /// The server name used to store Bookish's Google Books API key.
  static let googleBooksServer = "www.googleapis.com"

  /// The account name used to store Bookish's OpenAI API key.
  static let openAIAccount = "openai-api-key"

  /// The server name used to store Bookish's OpenAI API key.
  static let openAIServer = "api.openai.com"

  /// The Google Books credential, when the application has one.
  let googleBooksAPIKey: String?

  /// The OpenAI credential, when the application has one.
  let openAIAPIKey: String?

  /// Creates explicit service configuration for application composition and tests.
  public init(googleBooksAPIKey: String? = nil, openAIAPIKey: String? = nil) {
    self.googleBooksAPIKey = Self.normalized(googleBooksAPIKey)
    self.openAIAPIKey = Self.normalized(openAIAPIKey)
  }

  /// Reads optional service credentials from the application's Keychain.
  static func load(using keychain: Keychain = .default) throws -> Self {
    Self(
      googleBooksAPIKey: try keychain.password(for: googleBooksAccount, on: googleBooksServer),
      openAIAPIKey: try keychain.password(for: openAIAccount, on: openAIServer)
    )
  }

  /// Returns the lookup providers enabled by this application configuration.
  var lookupProviders: [any BookLookupProvider] {
    let providers: [any BookLookupProvider] = [
      OpenLibraryLookupProvider(),
      FakeBookLookupProvider(),
      GoogleBooksLookupProvider(apiKey: googleBooksAPIKey),
    ]
    return providers
  }

  /// Returns the recognition providers enabled by this application configuration.
  var recognitionProviders: [any BookRecognitionProvider] {
    var recognitionProviders: [any BookRecognitionProvider] = [
      FakeBookRecognitionProvider(),
      OnDeviceBookRecognitionProvider(),
      CloudComputeBookRecognitionProvider(),
      OCRBookRecognitionProvider(),
    ]
    if let openAIAPIKey {
      recognitionProviders.append(OpenAIResponsesBookRecognitionProvider(apiKey: openAIAPIKey))
    }
    return recognitionProviders
  }

  /// Converts blank configuration values into an absent credential.
  private static func normalized(_ value: String?) -> String? {
    guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty
    else { return nil }
    return value
  }
}
