import BookishRecord
import Foundation
import Testing

@testable import BookishImporter

struct KindleLibraryImporterTests {
  @Test
  func importsBooksFromSyntheticDatabase() async throws {
    let events = try await collect(
      KindleLibraryImporter().importEvents(from: KindleLibrarySource(url: fixtureURL())))
    let records = events.flatMap { event -> [BookishRecord] in
      guard case .records(let batch) = event else { return [] }
      return batch
    }
    let byID = Dictionary(
      records.map { ($0.id, $0) },
      uniquingKeysWith: { first, second in
        #expect(first == second)
        return first
      })

    let first = try #require(byID[BookishRecordID("kindle-book-B000000001")])
    #expect(first.kind == BookishRecordKind.book)
    #expect(first.string(BookishRecordKey.name) == "The Glass Orbit")
    #expect(first.string(BookishRecordKey.asin) == "B000000001")
    #expect(first.string(BookishRecordKey.source) == KindleLibraryImporter.sourceID)
    #expect(first.list(BookishRecordKey.authors)?.count == 1)
    #expect(first.list(BookishRecordKey.publishers)?.count == 1)
    #expect(first.properties[BookishRecordKey.publishedDate]?.dateValue != nil)
    #expect(first.properties[BookishRecordKey.addedDate]?.dateValue != nil)
    #expect(first.string(BookishRecordKey.originalData)?.contains("Purchase") == true)
    #expect(first.string(BookishRecordKey.originalData)?.contains("Sol, Ada") == true)

    let second = try #require(byID[BookishRecordID("kindle-book-B000000002")])
    #expect(second.string(BookishRecordKey.name) == "Tidal Atlas")
    #expect(second.list(BookishRecordKey.authors)?.count == 2)
    #expect(second.string(BookishRecordKey.originalData)?.contains("Sharing") == true)
    #expect(second.string(BookishRecordKey.originalData)?.contains("Reed, Mina") == true)
    #expect(byID.values.filter { $0.kind == BookishRecordKind.book }.count == 2)
    #expect(byID.values.contains { $0.string(BookishRecordKey.name) == "Ada Sol" })
    #expect(byID.values.contains { $0.string(BookishRecordKey.name) == "Mina Reed" })
    #expect(
      records.allSatisfy { $0.string(BookishRecordKey.source) == KindleLibraryImporter.sourceID })

    let finish = try #require(events.last)
    guard case .finished(let summary) = finish else {
      Issue.record("Expected Kindle import to finish.")
      return
    }
    #expect(summary.recordCount == records.count)
  }

  @Test
  func repeatedExtractionProducesTheSameProposals() async throws {
    let importer = KindleLibraryImporter()
    let first = try await collect(
      importer.importEvents(from: KindleLibrarySource(url: fixtureURL())))
    let second = try await collect(
      importer.importEvents(from: KindleLibrarySource(url: fixtureURL())))

    #expect(first == second)
  }

  @Test
  func acceptsContainingFolderAsSource() async throws {
    let source = KindleLibrarySource(url: fixtureURL().deletingLastPathComponent())
    let events = try await collect(KindleLibraryImporter().importEvents(from: source))
    #expect(
      events.contains { event in
        if case .records = event { return true }
        return false
      })
  }

  @Test
  func canReadAnOptionalLocalKindleDatabase() async throws {
    guard let path = ProcessInfo.processInfo.environment["BOOKISH_KINDLE_TEST_DATABASE"] else {
      return
    }
    let events = try await collect(
      KindleLibraryImporter().importEvents(
        from: KindleLibrarySource(url: URL(fileURLWithPath: path))))
    let books = events.flatMap { event -> [BookishRecord] in
      guard case .records(let records) = event else { return [] }
      return records.filter { $0.kind == BookishRecordKind.book }
    }
    #expect(!books.isEmpty)
    if let expected = ProcessInfo.processInfo.environment["BOOKISH_KINDLE_EXPECTED_BOOK_COUNT"]
      .flatMap(Int.init)
    {
      #expect(books.count == expected)
    }
  }

  private func fixtureURL() -> URL {
    Bundle.module.url(forResource: "BookData", withExtension: "sqlite")!
  }

  private func collect(
    _ stream: AsyncThrowingStream<BookishImportEvent, Error>
  ) async throws -> [BookishImportEvent] {
    var events: [BookishImportEvent] = []
    for try await event in stream { events.append(event) }
    return events
  }
}
