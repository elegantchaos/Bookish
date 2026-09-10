// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Keychain

/// Provides credentials required by book-recognition services.
public protocol BookRecognitionCredentials: Sendable {
  /// Returns the OpenAI API key, or `nil` when it has not been stored.
  func openAIAPIKey() throws -> String?
}

/// Reads Bookish's OpenAI API key from the user's keychain.
public struct KeychainBookRecognitionCredentials: BookRecognitionCredentials {
  /// The dedicated account name for Bookish's OpenAI credential.
  public static let openAIAccount = "openai-api-key"

  /// The OpenAI API host used as the keychain item's server.
  public static let openAIServer = "api.openai.com"

  /// Creates a Keychain-backed credential provider.
  public init() {
  }

  /// Reads the API key from the dedicated OpenAI internet-password item.
  public func openAIAPIKey() throws -> String? {
    try Keychain.default.password(for: Self.openAIAccount, on: Self.openAIServer)
  }
}
