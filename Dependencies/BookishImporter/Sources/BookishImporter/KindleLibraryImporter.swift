import BookishRecord
import CryptoKit
import Foundation
import SQLite3

// TODO: de-dupe and cleanup like Delicious importer?
// TODO: author names in correct order
// TODO: series detection?
// TODO: use ASIN to detect the same book already imported via Delicious?
// TODO: can we differentiate between my books and books via family sharing?

/// A Kindle database or its containing directory, with record IDs already imported.
public struct KindleLibrarySource: Equatable, Sendable {
  public var url: URL
  public var existingRecordIDs: Set<BookishRecordID>

  public init(url: URL, existingRecordIDs: Set<BookishRecordID> = []) {
    self.url = url
    self.existingRecordIDs = existingRecordIDs
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
        var seen = source.existingRecordIDs
        var recordCount = 0
        var diagnostics: [String] = []
        continuation.yield(
          .progress(
            BookishImportProgress(
              message: "Importing Kindle library", completed: 0, total: total)))

        for (offset, book) in books.enumerated() {
          try Task.checkCancellation()
          if let records = try book.records() {
            guard let bookRecord = records.last else { continue }
            if seen.contains(bookRecord.id) {
              continuation.yield(
                .progress(
                  BookishImportProgress(
                    message: "Importing Kindle library", completed: offset + 1, total: total)))
              continue
            }
            let newRecords = records.filter { seen.insert($0.id).inserted }
            if !newRecords.isEmpty {
              recordCount += newRecords.count
              continuation.yield(.records(newRecords))
            }
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
      SELECT ZDISPLAYTITLE, ZRAWPUBLISHER, ZRAWPUBLICATIONDATE, ZLANGUAGE,
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
      let title = sqlite3_column_text(statement, 0).map { String(cString: $0) }
      let publisher = sqlite3_column_text(statement, 1).map { String(cString: $0) }
      let published =
        sqlite3_column_type(statement, 2) == SQLITE_NULL
        ? nil : Date(timeIntervalSince1970: sqlite3_column_double(statement, 2))
      let language = sqlite3_column_text(statement, 3).map { String(cString: $0) }
      let metadata: [String: Any]
      if let bytes = sqlite3_column_blob(statement, 4) {
        let data = Data(bytes: bytes, count: Int(sqlite3_column_bytes(statement, 4)))
        metadata = KindleMetadata.decode(data)
      } else {
        metadata = [:]
      }
      books.append(
        KindleBook(
          title: title, publisher: publisher, published: published, language: language,
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
    var snapshot: [String: Any] = ["ASIN": asin, "title": title]
    if let language, !language.isEmpty { snapshot["language"] = language }
    if let published {
      properties[BookishRecordKey.publishedDate] = try BookishRecordValue(date: published)
      snapshot["publishedDate"] = published.ISO8601Format()
    }
    if let purchaseDate = metadata["purchase_date"] as? String {
      let formatter = DateFormatter()
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
      if let date = formatter.date(from: purchaseDate) {
        properties[BookishRecordKey.addedDate] = try BookishRecordValue(date: date)
        snapshot["purchaseDate"] = purchaseDate
      }
    }
    var related: [BookishRecord] = []
    if let author = (metadata["authors"] as? [String: Any])?["author"] as? String,
      !author.isEmpty
    {
      let id = BookishRecordID("kindle-person-\(author.kindleIDComponent)")
      related.append(
        BookishRecord(
          id: id, kind: BookishRecordKind.person,
          properties: [
            BookishRecordKey.name: .string(author),
            BookishRecordKey.source: .string(KindleLibraryImporter.sourceID),
          ]))
      properties[BookishRecordKey.authors] = .list([.record(id)])
      snapshot["author"] = author
    }
    if let publisher, !publisher.isEmpty {
      let id = BookishRecordID("kindle-organisation-\(publisher.kindleIDComponent)")
      related.append(
        BookishRecord(
          id: id, kind: BookishRecordKind.organisation,
          properties: [
            BookishRecordKey.name: .string(publisher),
            BookishRecordKey.source: .string(KindleLibraryImporter.sourceID),
          ]))
      properties[BookishRecordKey.publishers] = .list([.record(id)])
      snapshot["publisher"] = publisher
    }
    if let origins = metadata["origins"] as? [String: Any] { snapshot["origins"] = origins }
    let snapshotData = try JSONSerialization.data(withJSONObject: snapshot, options: [.sortedKeys])
    properties[BookishRecordKey.originalData] = .string(
      String(decoding: snapshotData, as: UTF8.self))
    return related + [
      BookishRecord(id: bookID, kind: BookishRecordKind.book, properties: properties)
    ]
  }
}

extension String {
  fileprivate var kindleIDComponent: String {
    SHA256.hash(data: Data(utf8)).map { String(format: "%02x", $0) }.joined()
  }
}
