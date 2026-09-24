import BookishRecord
import CryptoKit
import Foundation
import SQLite3

// TODO: series detection?
// TODO: can we differentiate between my books and books via family sharing?

/// A Kindle database or its containing directory.
public struct KindleLibrarySource: Equatable, Sendable {
  public var url: URL

  public init(url: URL) {
    self.url = url
  }
}

/// Reads book metadata from the local Kindle for Mac database.
public struct KindleLibraryImporter: BookishImporter {
  public static let sourceID = "com.elegantchaos.bookish.importer.kindle-library"

  public init() {}

  public var descriptor: BookishImporterDescriptor {
    BookishImporterDescriptor(sourceID: Self.sourceID, displayName: "Kindle library")
  }

  public func importEvents(from source: KindleLibrarySource) -> AsyncThrowingStream<
    BookishImportEvent, Error
  > {
    let (stream, continuation) = AsyncThrowingStream.makeStream(
      of: BookishImportEvent.self, throwing: Error.self)
    let importer = self
    let task = Task.detached {
      do {
        continuation.yield(.started(BookishImportStart(importer: importer.descriptor)))
        let url =
          source.url.hasDirectoryPath
          ? source.url.appendingPathComponent("BookData.sqlite") : source.url
        let database = try KindleDatabase(url: url)
        let books = try database.books()
        let total = books.count
        var recordCount = 0
        var diagnostics: [String] = []
        continuation.yield(
          .progress(
            BookishImportProgress(
              message: "Importing Kindle library", completed: 0, total: total)))

        for (offset, book) in books.enumerated() {
          try Task.checkCancellation()
          if let records = try book.records() {
            recordCount += records.count
            continuation.yield(.records(records))
          } else {
            diagnostics.append("Skipped a Kindle book without a usable ASIN or title.")
          }
          continuation.yield(
            .progress(
              BookishImportProgress(
                message: "Importing Kindle library", completed: offset + 1, total: total)))
          await Task.yield()
        }
        continuation.yield(
          .finished(
            BookishImportSummary(
              sourceID: Self.sourceID, recordCount: recordCount, diagnostics: diagnostics)))
        continuation.finish()
      } catch is CancellationError {
        continuation.finish()
      } catch {
        continuation.finish(throwing: error)
      }
    }
    continuation.onTermination = { _ in task.cancel() }
    return stream
  }
}

private final class KindleDatabase {
  private var handle: OpaquePointer?

  init(url: URL) throws {
    guard sqlite3_open_v2(url.path, &handle, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
      throw BookishImportError.invalidSource
    }
  }

  deinit { sqlite3_close(handle) }

  func books() throws -> [KindleBook] {
    let sql = """
      SELECT ZBOOKID, ZDISPLAYTITLE, ZRAWPUBLISHER, ZRAWPUBLICATIONDATE, ZLANGUAGE,
             ZSYNCMETADATAATTRIBUTES
      FROM ZBOOK WHERE ZRAWBOOKTYPE = 10 ORDER BY ZBOOKID
      """
    var statement: OpaquePointer?
    guard sqlite3_prepare_v2(handle, sql, -1, &statement, nil) == SQLITE_OK else {
      throw BookishImportError.unsupportedSource
    }
    defer { sqlite3_finalize(statement) }
    var books: [KindleBook] = []
    var status = sqlite3_step(statement)
    while status == SQLITE_ROW {
      let sourceBookID = sqlite3_column_text(statement, 0).map { String(cString: $0) }
      let title = sqlite3_column_text(statement, 1).map { String(cString: $0) }
      let publisher = sqlite3_column_text(statement, 2).map { String(cString: $0) }
      let published =
        sqlite3_column_type(statement, 3) == SQLITE_NULL
        ? nil : Date(timeIntervalSince1970: sqlite3_column_double(statement, 3))
      let language = sqlite3_column_text(statement, 4).map { String(cString: $0) }
      let metadata: [String: Any]
      if let bytes = sqlite3_column_blob(statement, 5) {
        let data = Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, 5)))
        metadata = KindleMetadata.decode(data)
      } else {
        metadata = [:]
      }
      books.append(
        KindleBook(
          sourceBookID: sourceBookID, title: title, publisher: publisher, published: published,
          language: language,
          metadata: metadata))
      status = sqlite3_step(statement)
    }
    guard status == SQLITE_DONE else { throw BookishImportError.invalidSource }
    return books
  }
}

@objc(BookishKindleSyncMetadataAttributes)
private final class KindleMetadata: NSObject, NSCoding {
  let attributes: [String: Any]

  required init?(coder: NSCoder) {
    guard let attributes = coder.decodeObject(forKey: "attributes") as? [String: Any] else {
      return nil
    }
    self.attributes = attributes
  }

  func encode(with coder: NSCoder) {}

  static func decode(_ data: Data) -> [String: Any] {
    guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else { return [:] }
    defer { unarchiver.finishDecoding() }
    unarchiver.requiresSecureCoding = false
    unarchiver.setClass(Self.self, forClassName: "SyncMetadataAttributes")
    return (unarchiver.decodeObject(forKey: NSKeyedArchiveRootObjectKey) as? Self)?.attributes
      ?? [:]
  }
}

private struct KindleBook {
  let sourceBookID: String?
  let title: String?
  let publisher: String?
  let published: Date?
  let language: String?
  let metadata: [String: Any]

  func records() throws -> [BookishRecord]? {
    guard let asin = metadata["ASIN"] as? String, !asin.isEmpty,
      let title, !title.isEmpty
    else { return nil }
    let bookID = BookishRecordID("kindle-book-\(asin)")
    var properties: [String: BookishRecordValue] = [
      BookishRecordKey.name: .string(title),
      BookishRecordKey.asin: .string(asin),
      BookishRecordKey.importedID: .string(asin),
      BookishRecordKey.source: .string(KindleLibraryImporter.sourceID),
      BookishRecordKey.format: .string("Kindle"),
    ]
    var snapshot: [String: Any] = [
      "displayTitle": title,
      "syncMetadataAttributes": metadata,
    ]
    if let sourceBookID { snapshot["bookID"] = sourceBookID }
    if let publisher { snapshot["rawPublisher"] = publisher }
    if let language, !language.isEmpty { snapshot["language"] = language }
    if let published {
      properties[BookishRecordKey.publishedDate] = try BookishRecordValue(date: published)
      snapshot["rawPublicationDate"] = published.timeIntervalSince1970
    }
    if let purchaseDate = metadata["purchase_date"] as? String {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
      if let date = formatter.date(from: purchaseDate) {
        properties[BookishRecordKey.addedDate] = try BookishRecordValue(date: date)
      }
    }
    var related: [BookishRecord] = []
    let rawAuthors = (metadata["authors"] as? [String: Any])?["author"]
    let authors: [String]
    switch rawAuthors {
    case let author as String: authors = [author]
    case let values as [String]: authors = values
    default: authors = []
    }
    var authorIDs: [BookishRecordID] = []
    for author in authors where !author.isEmpty {
      let id = BookishRecordID("kindle-person-\(author.kindleIDComponent)")
      authorIDs.append(id)
      let originalData = try Self.originalData(["author": author])
      related.append(
        BookishRecord(
          id: id, kind: BookishRecordKind.person,
          properties: [
            BookishRecordKey.name: .string(author.kindleDisplayName),
            BookishRecordKey.source: .string(KindleLibraryImporter.sourceID),
            BookishRecordKey.importedID: .string(author),
            BookishRecordKey.originalData: .string(originalData),
          ]))
    }
    if !authorIDs.isEmpty {
      properties[BookishRecordKey.authors] = .list(authorIDs.map { .record($0) })
    }
    if let publisher, !publisher.isEmpty {
      let id = BookishRecordID("kindle-organisation-\(publisher.kindleIDComponent)")
      let originalData = try Self.originalData(["publisher": publisher])
      related.append(
        BookishRecord(
          id: id, kind: BookishRecordKind.organisation,
          properties: [
            BookishRecordKey.name: .string(publisher),
            BookishRecordKey.source: .string(KindleLibraryImporter.sourceID),
            BookishRecordKey.importedID: .string(publisher),
            BookishRecordKey.originalData: .string(originalData),
          ]))
      properties[BookishRecordKey.publishers] = .list([.record(id)])
    }
    properties[BookishRecordKey.originalData] = .string(try Self.originalData(snapshot))
    return related + [
      BookishRecord(id: bookID, kind: BookishRecordKind.book, properties: properties)
    ]
  }

  private static func originalData(_ snapshot: [String: Any]) throws -> String {
    let data = try JSONSerialization.data(withJSONObject: snapshot, options: [.sortedKeys])
    return String(decoding: data, as: UTF8.self)
  }
}

extension String {
  fileprivate var kindleDisplayName: String {
    let parts = split(separator: ",", omittingEmptySubsequences: false)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    guard parts.count == 2, parts.allSatisfy({ !$0.isEmpty }) else { return self }
    return "\(parts[1]) \(parts[0])"
  }

  fileprivate var kindleIDComponent: String {
    SHA256.hash(data: Data(utf8)).map { String(format: "%02x", $0) }.joined()
  }
}
