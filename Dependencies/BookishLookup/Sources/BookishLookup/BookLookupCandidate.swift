// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Foundation

/// Represents metadata for one book returned by a lookup provider.
///
/// The candidate deliberately remains independent of Bookish's persistence model.
/// Application code can review it, preserve its provenance, then map it to records.
public struct BookLookupCandidate: Codable, Equatable, Identifiable, Sendable {
  /// The provider that returned this candidate.
  public let providerID: String

  /// The provider's stable identifier for this candidate, when it supplied one.
  public let sourceID: String?

  /// The primary book title.
  public let title: String

  /// The optional subtitle.
  public let subtitle: String?

  /// The book's credited contributors.
  public let authors: [String]

  /// The named publisher, when supplied.
  public let publisher: String?

  /// The publication date exactly as the provider supplied it.
  public let publishedDate: String?

  /// The ISBN-10 identifier, when supplied.
  public let isbn10: String?

  /// The ISBN-13 identifier, when supplied.
  public let isbn13: String?

  /// The page count, when supplied.
  public let pageCount: Int?

  /// The preferred cover-art URL, when supplied.
  public let coverURL: URL?

  /// The provider's raw payload for later inspection or improved mapping.
  public let rawData: Data?

  /// The provider metadata expressed as Bookish's canonical record snapshot.
  public let record: BookishRecord

  /// A stable identifier for the candidate while it remains in a lookup result.
  public var id: String {
    [providerID, sourceID ?? title, authors.joined(separator: ",")]
      .joined(separator: "|")
  }

  /// Creates a candidate from provider metadata.
  public init(
    providerID: String,
    sourceID: String? = nil,
    title: String,
    subtitle: String? = nil,
    authors: [String] = [],
    publisher: String? = nil,
    publishedDate: String? = nil,
    isbn10: String? = nil,
    isbn13: String? = nil,
    pageCount: Int? = nil,
    coverURL: URL? = nil,
    rawData: Data? = nil
  ) {
    self.providerID = providerID
    self.sourceID = sourceID
    self.title = title
    self.subtitle = subtitle
    self.authors = authors
    self.publisher = publisher
    self.publishedDate = publishedDate
    self.isbn10 = isbn10
    self.isbn13 = isbn13
    self.pageCount = pageCount
    self.coverURL = coverURL
    self.rawData = rawData
    record = Self.makeRecord(
      providerID: providerID,
      sourceID: sourceID,
      title: title,
      subtitle: subtitle,
      isbn13: isbn13,
      isbn10: isbn10,
      pageCount: pageCount
    )
  }

  /// Converts metadata that Bookish currently models directly into a book record.
  private static func makeRecord(
    providerID: String,
    sourceID: String?,
    title: String,
    subtitle: String?,
    isbn13: String?,
    isbn10: String?,
    pageCount: Int?
  ) -> BookishRecord {
    var properties: [String: BookishRecordValue] = [
      BookishRecordKey.name: .string(title),
      BookishRecordKey.source: .string(providerID),
    ]
    if let sourceID { properties[BookishRecordKey.importedID] = .string(sourceID) }
    if let subtitle { properties[BookishRecordKey.subtitle] = .string(subtitle) }
    if let isbn = isbn13 ?? isbn10 { properties[BookishRecordKey.isbn] = .string(isbn) }
    if let pageCount { properties[BookishRecordKey.pages] = .integer(pageCount) }
    let identitySource = sourceID ?? title
    let identity = identitySource.map { character in
      character.isLetter || character.isNumber ? String(character) : "-"
    }.joined()
    return BookishRecord(
      id: BookishRecordID("lookup.\(providerID).\(identity)"),
      kind: BookishRecordKind.book,
      properties: properties
    )
  }
}
