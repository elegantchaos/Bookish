// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Retrieves work-level metadata from Open Library's public search API.
///
/// The search API deliberately returns works rather than a single confirmed
/// edition. Clients must therefore present its candidates for review, rather
/// than treating an ISBN match as authoritative edition metadata.
public struct OpenLibraryLookupProvider: BookLookupProvider {
  /// The stable identifier for Open Library provenance.
  public let id: BookLookupProviderID = .openLibrary

  /// The user-facing provider name.
  public let label = "Open Library"

  /// Explains that Open Library returns work-level search candidates.
  public let description = "Searches Open Library for work-level candidates by ISBN or text."

  /// Performs requests to the Open Library API.
  private let session: URLSession

  /// Identifies Bookish to Open Library when the host application configures it.
  private let userAgent: String?

  /// Creates a provider using the supplied session and optional identifying header.
  ///
  /// Configure `userAgent` with an application name and support contact before
  /// shipping frequent requests, as requested by Open Library's usage policy.
  public init(session: URLSession = .shared, userAgent: String? = nil) {
    self.session = session
    self.userAgent = userAgent
  }

  /// Returns Open Library candidates matching a query.
  public func lookupBooks(matching query: BookLookupQuery) async throws -> [BookLookupCandidate] {
    let request = try makeRequest(for: query)
    let (data, response) = try await session.data(for: request)
    guard let response = response as? HTTPURLResponse else {
      throw BookLookupError.invalidResponse
    }
    guard (200...299).contains(response.statusCode) else {
      throw BookLookupError.serverError(
        statusCode: response.statusCode,
        message: "Open Library request failed (HTTP \(response.statusCode))."
      )
    }

    return try JSONDecoder()
      .decode(OpenLibrarySearchResponse.self, from: data)
      .documents
      .map { document in
        BookLookupCandidate(
          providerID: id,
          sourceID: document.key,
          title: document.title,
          authors: document.authorNames ?? [],
          publisher: document.publisherNames?.first,
          publishedDate: document.firstPublishedYear.map(String.init),
          isbn10: document.isbn(ofLength: 10),
          isbn13: document.isbn(ofLength: 13),
          pageCount: document.pageCount,
          coverURL: document.coverURL,
          rawData: try? JSONEncoder().encode(document)
        )
      }
  }

  /// Creates a bounded search request using only the fields Bookish currently maps.
  private func makeRequest(for query: BookLookupQuery) throws -> URLRequest {
    var components = URLComponents(string: "https://openlibrary.org/search.json")
    components?.queryItems = [
      URLQueryItem(name: "q", value: query.text),
      URLQueryItem(name: "limit", value: "10"),
      URLQueryItem(
        name: "fields",
        value:
          "key,title,author_name,publisher,first_publish_year,isbn,number_of_pages_median,cover_i"
      ),
    ]
    guard let url = components?.url else {
      throw BookLookupError.invalidResponse
    }
    var request = URLRequest(url: url)
    if let userAgent, !userAgent.isEmpty {
      request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
    }
    return request
  }
}
