// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Testing

@testable import BookishLookup

/// Verifies Open Library request construction and metadata mapping.
struct OpenLibraryLookupProviderTests {
  /// Maps Open Library search documents without performing a live request.
  @Test
  func openLibraryProviderMapsSearchMetadata() async throws {
    let fixture = RecordingLookupSession(responseData: Self.responseData)
    defer { fixture.close() }
    let provider = OpenLibraryLookupProvider(
      session: fixture.session,
      userAgent: "BookishTests (tests@example.com)"
    )

    let candidates = try await provider.lookupBooks(matching: BookLookupQuery("9780441478125"))

    #expect(candidates.count == 1)
    let candidate = try #require(candidates.first)
    #expect(candidate.providerID == .openLibrary)
    #expect(candidate.sourceID == "/works/OL262758W")
    #expect(candidate.title == "The Left Hand of Darkness")
    #expect(candidate.authors == ["Ursula K. Le Guin"])
    #expect(candidate.publisher == "Ace Books")
    #expect(candidate.publishedDate == "1969")
    #expect(candidate.isbn10 == "0441478123")
    #expect(candidate.isbn13 == "9780441478125")
    #expect(candidate.pageCount == 304)
    #expect(candidate.coverURL == URL(string: "https://covers.openlibrary.org/b/id/12345-L.jpg"))
    #expect(candidate.rawData != nil)
    let request = try #require(fixture.request)
    #expect(request.url?.host == "openlibrary.org")
    #expect(request.url?.path == "/search.json")
    #expect(request.value(forHTTPHeaderField: "User-Agent") == "BookishTests (tests@example.com)")
    let requestURL = try #require(request.url)
    let queryItems = try #require(
      URLComponents(url: requestURL, resolvingAgainstBaseURL: false)?.queryItems)
    #expect(queryItems.contains(URLQueryItem(name: "q", value: "9780441478125")))
    #expect(queryItems.contains(URLQueryItem(name: "limit", value: "10")))
    #expect(
      queryItems.contains(
        URLQueryItem(
          name: "fields",
          value:
            "key,title,author_name,publisher,first_publish_year,isbn,number_of_pages_median,cover_i"
        )))
  }

  /// The deterministic Open Library response used by the provider test.
  private static let responseData = Data(
    """
    {
      "docs": [
        {
          "key": "/works/OL262758W",
          "title": "The Left Hand of Darkness",
          "author_name": ["Ursula K. Le Guin"],
          "publisher": ["Ace Books"],
          "first_publish_year": 1969,
          "isbn": ["0441478123", "9780441478125"],
          "number_of_pages_median": 304,
          "cover_i": 12345
        }
      ]
    }
    """.utf8
  )
}
