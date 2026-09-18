// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Retrieves book metadata from the Google Books volumes API.
public struct GoogleBooksLookupProvider: BookLookupProvider {
  /// The stable identifier for Google Books provenance.
  public let id = "google-books"

  /// The user-facing provider name.
  public let label = "Google Books"

  /// Explains that results are retrieved from Google's public books catalogue.
  public let description = "Searches the Google Books catalogue by ISBN or text."

  /// Performs requests to the Google Books API.
  private let session: URLSession

  /// The API key supplied by the application when it constructs this provider.
  private let apiKey: String

  /// Creates a provider using an API key supplied by the application.
  public init(
    apiKey: String,
    session: URLSession = .shared
  ) {
    self.apiKey = apiKey
    self.session = session
  }

  /// Returns Google Books candidates matching a query.
  public func lookupBooks(matching query: BookLookupQuery) async throws -> [BookLookupCandidate] {
    let request = try makeRequest(for: query, apiKey: apiKey)
    let (data, response) = try await session.data(for: request)
    guard let response = response as? HTTPURLResponse else {
      throw BookLookupError.invalidResponse
    }
    guard (200...299).contains(response.statusCode) else {
      throw BookLookupError.serverError(
        statusCode: response.statusCode,
        message: "Google Books request failed (HTTP \(response.statusCode))."
      )
    }

    return try JSONDecoder()
      .decode(GoogleBooksResponse.self, from: data)
      .items
      .map { item in
        BookLookupCandidate(
          providerID: id,
          sourceID: item.id,
          title: item.volumeInfo.title,
          subtitle: item.volumeInfo.subtitle,
          authors: item.volumeInfo.authors ?? [],
          publisher: item.volumeInfo.publisher,
          publishedDate: item.volumeInfo.publishedDate,
          isbn10: item.volumeInfo.identifier(ofType: "ISBN_10"),
          isbn13: item.volumeInfo.identifier(ofType: "ISBN_13"),
          pageCount: item.volumeInfo.pageCount,
          coverURL: item.volumeInfo.imageLinks?.thumbnail.map(secureURL(from:)),
          rawData: try? JSONEncoder().encode(item)
        )
      }
  }

  /// Creates an API request that searches by ISBN when the query contains one.
  private func makeRequest(for query: BookLookupQuery, apiKey: String) throws -> URLRequest {
    var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
    components?.queryItems = [
      URLQueryItem(name: "q", value: googleQuery(for: query)),
      URLQueryItem(name: "key", value: apiKey),
    ]
    guard let url = components?.url else {
      throw BookLookupError.invalidResponse
    }
    return URLRequest(url: url)
  }

  /// Converts an ISBN query into Google's ISBN-specific query syntax.
  private func googleQuery(for query: BookLookupQuery) -> String {
    let normalizedISBN = query.text.filter { $0.isLetter || $0.isNumber }.uppercased()
    let isISBN = normalizedISBN.count == 10 || normalizedISBN.count == 13
    return isISBN ? "isbn:\(normalizedISBN)" : query.text
  }

  /// Upgrades legacy HTTP cover URLs before exposing them to the application.
  private func secureURL(from url: URL) -> URL {
    guard url.scheme == "http" else { return url }
    var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
    components?.scheme = "https"
    return components?.url ?? url
  }
}
