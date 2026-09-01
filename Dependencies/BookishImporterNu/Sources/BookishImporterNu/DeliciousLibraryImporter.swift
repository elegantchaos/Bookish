// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 02/06/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCleanup
import BookishRecord
import Foundation

/// Imports Delicious Library XML property-list exports into normalised Bookish records.
public struct DeliciousLibraryImporter: BookishImporter {
  /// The stable importer identifier.
  public static let sourceID = "com.elegantchaos.bookish.importer.delicious-library"

  /// Creates a Delicious Library importer.
  public init() {
  }

  /// Metadata used by import coordinators and user interfaces.
  public var descriptor: BookishImporterDescriptor {
    BookishImporterDescriptor(sourceID: Self.sourceID, displayName: "Delicious Library")
  }

  /// Imports Delicious Library data while emitting normalised record batches and progress updates.
  public func importEvents(from data: Data) -> AsyncThrowingStream<BookishImportEvent, Error> {
    let (stream, continuation) = AsyncThrowingStream.makeStream(
      of: BookishImportEvent.self,
      throwing: Error.self
    )
    let importer = self

    let task = Task {
      do {
        continuation.yield(.started(BookishImportStart(importer: importer.descriptor)))
        let list = try importer.decodeSource(data)
        let total = list.count
        continuation.yield(
          .progress(
            BookishImportProgress(
              message: "Importing Delicious Library", completed: 0, total: total)))

        var builder = DeliciousRecordGraphBuilder(sourceID: Self.sourceID)
        let root = BookishRecordID("delicious-import")
        var bookIDs: [BookishRecordID] = []
        var recordCount = 0

        for (offset, rawRecord) in list.enumerated() {
          try Task.checkCancellation()

          if let book = DeliciousBook(rawRecord, sourceID: Self.sourceID) {
            let bookID = builder.addBook(importer.clean(book))
            bookIDs.append(bookID)
          }

          let records = builder.drainChangedRecords()
          if !records.isEmpty {
            recordCount += records.count
            continuation.yield(.records(records))
          }
          continuation.yield(
            .progress(
              BookishImportProgress(
                message: "Importing Delicious Library", completed: offset + 1, total: total)))
          await Task.yield()
        }

        builder.addRootList(id: root, bookIDs: bookIDs)
        let rootRecords = builder.drainChangedRecords()
        recordCount += rootRecords.count
        continuation.yield(.records(rootRecords))
        continuation.yield(
          .finished(
            BookishImportSummary(
              sourceID: Self.sourceID, root: root, recordCount: recordCount,
              diagnostics: builder.diagnostics)))
        continuation.finish()
      } catch is CancellationError {
        continuation.finish()
      } catch {
        continuation.finish(throwing: error)
      }
    }

    continuation.onTermination = { _ in
      task.cancel()
    }
    return stream
  }

  /// Imports records from a Delicious Library XML property-list URL.
  public func importRecords(from url: URL) throws -> BookishImportResult {
    let data = try Data(contentsOf: url)
    return try importRecords(from: data)
  }

  /// Imports records from Delicious Library XML property-list data.
  public func importRecords(from data: Data) throws -> BookishImportResult {
    try buildResult(from: decodeSource(data))
  }

  private func decodeSource(_ data: Data) throws -> [[String: Any]] {
    guard
      let list = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        as? [[String: Any]]
    else {
      throw BookishImportError.invalidSource
    }

    guard list.first?["actorsCompositeString"] != nil else {
      throw BookishImportError.unsupportedSource
    }

    return list
  }

  private func buildResult(from list: [[String: Any]]) -> BookishImportResult {
    var builder = DeliciousRecordGraphBuilder(sourceID: Self.sourceID)
    let root = BookishRecordID("delicious-import")
    var bookIDs: [BookishRecordID] = []

    for rawRecord in list {
      guard let book = DeliciousBook(rawRecord, sourceID: Self.sourceID) else {
        continue
      }

      let cleaned = clean(book)
      let bookID = builder.addBook(cleaned)
      bookIDs.append(bookID)
    }

    builder.addRootList(id: root, bookIDs: bookIDs)
    return BookishImportResult(
      sourceID: Self.sourceID,
      root: root,
      records: builder.sortedRecords(),
      diagnostics: builder.diagnostics
    )
  }

  private func clean(_ book: DeliciousBook) -> DeliciousBook {
    let seriesCleaner = SeriesCleaner()
    let publisherCleaner = PublisherCleaner()
    var book = book

    if let cleaned = publisherCleaner.cleanup(
      book: .init(
        title: book.title,
        subtitle: book.subtitle,
        publishers: book.publishers,
        series: book.series
      )
    ) {
      book.apply(
        title: cleaned.title, subtitle: cleaned.subtitle, publishers: cleaned.publishers,
        series: cleaned.series)
    }

    if let cleaned = seriesCleaner.cleanup(
      book: .init(
        title: book.title,
        subtitle: book.subtitle,
        series: book.series,
        position: book.seriesPosition ?? 0
      )
    ) {
      book.apply(
        title: cleaned.title,
        subtitle: cleaned.subtitle,
        series: cleaned.series,
        seriesPosition: cleaned.position == 0 ? nil : cleaned.position
      )
    }

    return book
  }
}

private struct DeliciousBook {
  var id: String
  var sourceID: String
  var title: String
  var subtitle: String
  var properties: [String: BookishRecordValue]
  var authors: [String]
  var illustrators: [String]
  var publishers: [String]
  var series: String
  var seriesPosition: Int?

  init?(_ raw: [String: Any], sourceID: String) {
    guard let title = raw.string("title"), !title.isEmpty else {
      return nil
    }

    let format = raw.string("formatSingularString")
    guard format.map(Self.skippedFormats.contains) != true else {
      return nil
    }

    let type = raw.string("type")
    guard type.map(Self.skippedFormats.contains) != true else {
      return nil
    }

    self.id =
      raw.string("uuidString") ?? raw.string("foreignUUIDString") ?? "delicious-import-\(title)"
    self.sourceID = sourceID
    self.title = title
    self.subtitle = raw.string("subtitle") ?? ""
    self.authors = raw.stringList("creatorsCompositeString")
    self.illustrators = raw.stringList("illustratorsCompositeString")
    self.publishers = raw.stringList("publishersCompositeString")
    self.series = raw.string("seriesSingularString") ?? ""
    self.seriesPosition = raw.nonZeroInt("numberInSeries")

    var properties: [String: BookishRecordValue] = [
      "title": .string(title),
      "importedID": .string(id),
      "source": .string(sourceID),
    ]

    properties.addString(raw.string("formatSingularString"), forKey: "format")
    properties.addString(raw.string("subtitle"), forKey: "subtitle")
    properties.addString(raw.string("asin"), forKey: "asin")
    properties.addString(raw.string("deweyDecimal"), forKey: "dewey")
    properties.addString(raw.string("isbn"), forKey: "isbn")
    properties.addInteger(raw.nonZeroInt("pages"), forKey: "pages")
    properties.addInteger(raw.nonZeroInt("numberInSeries"), forKey: "seriesPosition")
    properties.addDouble(raw.nonZeroDouble("boxHeightInInches"), forKey: "height")
    properties.addDouble(raw.nonZeroDouble("boxWidthInInches"), forKey: "width")
    properties.addDouble(raw.nonZeroDouble("boxLengthInInches"), forKey: "length")
    properties.addDate(raw.date("creationDate"), forKey: "addedDate")
    properties.addDate(raw.date("lastModificationDate"), forKey: "modifiedDate")
    properties.addDate(raw.date("publishDate"), forKey: "publishedDate")
    properties.addStringList(raw.stringList("editionsCompositeString"), forKey: "editions")
    properties.addStringList(raw.stringList("genresCompositeString"), forKey: "genres")
    properties.addStringList(raw.imageURLs, forKey: "imageURLs")

    self.properties = properties
  }

  mutating func apply(
    title: String,
    subtitle: String,
    publishers: [String]? = nil,
    series: String? = nil,
    seriesPosition: Int? = nil
  ) {
    if self.title != title {
      properties["original.title"] = .string(self.title)
      self.title = title
      properties["title"] = .string(title)
    }

    if self.subtitle != subtitle {
      if !self.subtitle.isEmpty {
        properties["original.subtitle"] = .string(self.subtitle)
      }
      self.subtitle = subtitle
      properties.addString(subtitle, forKey: "subtitle")
    }

    if let publishers, self.publishers != publishers {
      if !self.publishers.isEmpty {
        properties["original.publishers"] = .list(self.publishers.map { .string($0) })
      }
      self.publishers = publishers
    }

    if let series, self.series != series {
      if !self.series.isEmpty {
        properties["original.series"] = .string(self.series)
      }
      self.series = series
    }

    if let seriesPosition, self.seriesPosition != seriesPosition {
      if let existing = self.seriesPosition {
        properties["original.seriesPosition"] = .integer(existing)
      }
      self.seriesPosition = seriesPosition
      properties["seriesPosition"] = .integer(seriesPosition)
    }
  }

  private static let skippedFormats = [
    "Audio CD", "Audio CD Enhanced", "Audio CD Import", "Video Game", "VHS Tape", "VideoGame",
    "DVD",
  ]
}

private struct DeliciousRecordGraphBuilder {
  let sourceID: String
  var recordsByID: [BookishRecordID: BookishRecord] = [:]
  var diagnostics: [String] = []
  private var changedRecordIDs: Set<BookishRecordID> = []

  init(sourceID: String) {
    self.sourceID = sourceID
  }

  mutating func addBook(_ book: DeliciousBook) -> BookishRecordID {
    let bookID = BookishRecordID("delicious-book-\(book.id.normalizedIDComponent)")
    var properties = book.properties

    let authorIDs = book.authors.enumerated().map { index, name in
      addRelatedRecord(name: name, kind: "person")
        .also { addRelationship(role: "author", from: bookID, to: $0, position: index + 1) }
    }
    properties.addRecordList(authorIDs, forKey: "authors")

    let illustratorIDs = book.illustrators.enumerated().map { index, name in
      addRelatedRecord(name: name, kind: "person")
        .also { addRelationship(role: "illustrator", from: bookID, to: $0, position: index + 1) }
    }
    properties.addRecordList(illustratorIDs, forKey: "illustrators")

    let publisherIDs = book.publishers.enumerated().map { index, name in
      addRelatedRecord(name: name, kind: "organisation")
        .also { addRelationship(role: "publisher", from: bookID, to: $0, position: index + 1) }
    }
    properties.addRecordList(publisherIDs, forKey: "publishers")

    if !book.series.isEmpty {
      let seriesID = addRelatedRecord(name: book.series, kind: "series")
      properties["series"] = .record(seriesID)
      addRelationship(role: "series", from: bookID, to: seriesID, position: book.seriesPosition)
    }

    store(BookishRecord(id: bookID, kind: "book", properties: properties))
    return bookID
  }

  mutating func addRootList(id: BookishRecordID, bookIDs: [BookishRecordID]) {
    store(
      BookishRecord(
        id: id,
        kind: "list",
        properties: [
          "name": .string("Delicious Library Import"),
          "source": .string(sourceID),
          "items": .list(bookIDs.map { .record($0) }),
        ]))
  }

  func sortedRecords() -> [BookishRecord] {
    recordsByID.values.sorted { $0.id.rawValue < $1.id.rawValue }
  }

  mutating func drainChangedRecords() -> [BookishRecord] {
    defer {
      changedRecordIDs.removeAll()
    }
    return changedRecordIDs.compactMap { recordsByID[$0] }.sorted {
      $0.id.rawValue < $1.id.rawValue
    }
  }

  @discardableResult
  private mutating func addRelatedRecord(name: String, kind: String) -> BookishRecordID {
    let id = BookishRecordID("\(kind)-\(name.normalizedIDComponent)")
    guard recordsByID[id] == nil else {
      return id
    }

    store(
      BookishRecord(
        id: id,
        kind: kind,
        properties: [
          "name": .string(name),
          "source": .string(sourceID),
        ]))
    return id
  }

  private mutating func addRelationship(
    role: String,
    from source: BookishRecordID,
    to target: BookishRecordID,
    position: Int?
  ) {
    let id = BookishRecordID("relationship-\(role)-\(source.rawValue)-\(target.rawValue)")
    var properties: [String: BookishRecordValue] = [
      "role": .string(role),
      "from": .record(source),
      "to": .record(target),
      "source": .string(sourceID),
    ]
    properties.addInteger(position, forKey: "position")
    store(BookishRecord(id: id, kind: "relationship", properties: properties))
  }

  private mutating func store(_ record: BookishRecord) {
    recordsByID[record.id] = record
    changedRecordIDs.insert(record.id)
  }
}

extension Dictionary where Key == String, Value == Any {
  fileprivate var imageURLs: [String] {
    [
      string("coverImageLargeURLString"),
      string("coverImageMediumURLString"),
      string("coverImageSmallURLString"),
    ].compactMap { $0 }.filter { !$0.isEmpty }
  }

  fileprivate func string(_ key: String) -> String? {
    guard let value = self[key] else {
      return nil
    }

    switch value {
    case let string as String:
      let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
      return trimmed.isEmpty ? nil : trimmed

    case let number as NSNumber:
      return number.stringValue

    default:
      return nil
    }
  }

  fileprivate func stringList(_ key: String) -> [String] {
    guard let string = string(key) else {
      return []
    }

    return string.split(separator: "\n")
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  fileprivate func nonZeroInt(_ key: String) -> Int? {
    guard let number = self[key] as? NSNumber else {
      return nil
    }

    let value = number.intValue
    return value == 0 ? nil : value
  }

  fileprivate func nonZeroDouble(_ key: String) -> Double? {
    guard let number = self[key] as? NSNumber else {
      return nil
    }

    let value = number.doubleValue
    return value == 0 ? nil : value
  }

  fileprivate func date(_ key: String) -> Date? {
    self[key] as? Date
  }
}

extension Dictionary where Key == String, Value == BookishRecordValue {
  fileprivate mutating func addString(_ value: String?, forKey key: String) {
    guard let value, !value.isEmpty else {
      removeValue(forKey: key)
      return
    }

    self[key] = .string(value)
  }

  fileprivate mutating func addInteger(_ value: Int?, forKey key: String) {
    guard let value else {
      return
    }

    self[key] = .integer(value)
  }

  fileprivate mutating func addDouble(_ value: Double?, forKey key: String) {
    guard let value else {
      return
    }

    self[key] = .double(value)
  }

  fileprivate mutating func addDate(_ value: Date?, forKey key: String) {
    guard let value else {
      return
    }

    self[key] = .date(value)
  }

  fileprivate mutating func addStringList(_ values: [String], forKey key: String) {
    guard !values.isEmpty else {
      return
    }

    self[key] = .list(values.map { .string($0) })
  }

  fileprivate mutating func addRecordList(_ values: [BookishRecordID], forKey key: String) {
    guard !values.isEmpty else {
      return
    }

    self[key] = .list(values.map { .record($0) })
  }
}

extension String {
  fileprivate var normalizedIDComponent: String {
    let folded = folding(
      options: [.diacriticInsensitive, .caseInsensitive],
      locale: Locale(identifier: "en_US_POSIX")
    )
    let scalars = folded.unicodeScalars.map { scalar -> Character in
      if CharacterSet.alphanumerics.contains(scalar) {
        return Character(String(scalar).lowercased())
      }

      if scalar == "." || scalar == "_" || scalar == ":" || scalar == "-" {
        return Character(String(scalar))
      }

      return "-"
    }

    let collapsed = String(scalars)
      .split(separator: "-", omittingEmptySubsequences: true)
      .joined(separator: "-")

    return collapsed.isEmpty ? "unknown" : collapsed
  }
}

extension BookishRecordID {
  fileprivate func also(_ action: (BookishRecordID) -> Void) -> BookishRecordID {
    action(self)
    return self
  }
}
