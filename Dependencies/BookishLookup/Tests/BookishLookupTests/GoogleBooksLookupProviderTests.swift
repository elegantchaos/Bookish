// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Testing

@testable import BookishLookup

/// Verifies Google Books request construction and metadata mapping.
struct GoogleBooksLookupProviderTests {
  @Test
  func googleProviderRequiresAnAPIKey() async {
    let provider = GoogleBooksLookupProvider(apiKey: nil)

    #expect(provider.isSupported == false)

    do {
      _ = try await provider.lookupBooks(matching: BookLookupQuery("9780441478125"))
      Issue.record("Expected an unconfigured Google provider to reject lookups.")
    } catch BookLookupError.missingConfiguration {
    } catch {
      Issue.record("Expected missing configuration, received \(error).")
    }
  }

  @Test
  func googleProviderMapsGoogleBooksMetadata() async throws {
    let fixture = RecordingLookupSession(responseData: Self.responseData)
    defer { fixture.close() }
    let provider = GoogleBooksLookupProvider(
      apiKey: "test-key",
      session: fixture.session
    )

    let candidates = try await provider.lookupBooks(matching: BookLookupQuery("9780441478125"))

    #expect(candidates.count == 1)
    let candidate = try #require(candidates.first)
    #expect(candidate.providerID == .googleBooks)
    #expect(candidate.sourceID == "volume-id")
    #expect(candidate.title == "The Left Hand of Darkness")
    #expect(candidate.subtitle == "A Novel")
    #expect(candidate.authors == ["Ursula K. Le Guin"])
    #expect(candidate.publisher == "Ace Books")
    #expect(candidate.publishedDate == "1969-03-01")
    #expect(candidate.isbn10 == "0441478123")
    #expect(candidate.isbn13 == "9780441478125")
    #expect(candidate.pageCount == 304)
    #expect(candidate.coverURL == URL(string: "https://example.com/cover.jpg"))
    #expect(candidate.rawData != nil)
    let request = try #require(fixture.request)
    #expect(request.url?.host == "www.googleapis.com")
    let requestURL = try #require(request.url)
    let queryItems = try #require(
      URLComponents(url: requestURL, resolvingAgainstBaseURL: false)?.queryItems)
    #expect(queryItems.contains(URLQueryItem(name: "q", value: "isbn:9780441478125")))
    #expect(queryItems.contains(URLQueryItem(name: "key", value: "test-key")))
  }

  /// The deterministic Google Books response used by the provider test.
  private static let responseData = Data(
    """
    {
      "items": [
        {
          "id": "volume-id",
          "volumeInfo": {
            "title": "The Left Hand of Darkness",
            "subtitle": "A Novel",
            "authors": ["Ursula K. Le Guin"],
            "publisher": "Ace Books",
            "publishedDate": "1969-03-01",
            "industryIdentifiers": [
              {"type": "ISBN_10", "identifier": "0441478123"},
              {"type": "ISBN_13", "identifier": "9780441478125"}
            ],
            "pageCount": 304,
            "imageLinks": {"thumbnail": "http://example.com/cover.jpg"}
          }
        }
      ]
    }
    """.utf8
  )
}
