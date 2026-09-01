import BookishCoding
import BookishRecord
import Foundation
import Testing

@testable import BookishImporterNu

struct BookishImporterEventTests {
  @Test
  func deliciousLibraryStreamsNormalisedRecordsWithProgress() async throws {
    let data = try Data(contentsOf: deliciousSampleURL())
    let events = try await collect(DeliciousLibraryImporter().importEvents(from: data))

    let start = try #require(events.first)
    guard case .started(let importStart) = start else {
      Issue.record("Expected the first Delicious Library event to start the import.")
      return
    }
    #expect(importStart.importer == DeliciousLibraryImporter().descriptor)
    #expect(importStart.total == nil)

    let progress = events.compactMap { event -> BookishImportProgress? in
      guard case .progress(let progress) = event else {
        return nil
      }
      return progress
    }
    #expect(progress.first?.total == progress.last?.completed)
    #expect(progress.last?.completed ?? 0 > 0)

    let streamedRecords = events.flatMap { event -> [BookishRecord] in
      guard case .records(let records) = event else {
        return []
      }
      return records
    }
    let expected = try DeliciousLibraryImporter().importRecords(from: data)
    #expect(
      Dictionary(uniqueKeysWithValues: streamedRecords.map { ($0.id, $0) })
        == Dictionary(uniqueKeysWithValues: expected.records.map { ($0.id, $0) }))

    let finish = try #require(events.last)
    guard case .finished(let summary) = finish else {
      Issue.record("Expected the final Delicious Library event to finish the import.")
      return
    }
    #expect(summary.root == expected.root)
    #expect(summary.recordCount == streamedRecords.count)
  }

  @Test
  func interchangeStreamsDecodedRecordsInBatches() async throws {
    let root = BookishRecordID("import-root")
    let records = (0..<65).map { index in
      BookishRecord(
        id: BookishRecordID("book-\(index)"),
        kind: "book",
        properties: ["title": .string("Book \(index)")]
      )
    }
    let data = try BookishInterchangeCodec().encode(
      BookishInterchangeFile(root: root, records: records))
    let events = try await collect(BookishInterchangeImporter().importEvents(from: data))

    let recordBatches = events.compactMap { event -> [BookishRecord]? in
      guard case .records(let records) = event else {
        return nil
      }
      return records
    }
    #expect(recordBatches.map(\.count) == [64, 1])
    #expect(recordBatches.flatMap { $0 } == records)

    let finish = try #require(events.last)
    guard case .finished(let summary) = finish else {
      Issue.record("Expected the final interchange event to finish the import.")
      return
    }
    #expect(summary.root == root)
    #expect(summary.recordCount == records.count)
  }

  private func collect(
    _ stream: AsyncThrowingStream<BookishImportEvent, Error>
  ) async throws -> [BookishImportEvent] {
    var events: [BookishImportEvent] = []
    for try await event in stream {
      events.append(event)
    }
    return events
  }

  private func deliciousSampleURL() -> URL {
    let testFile = URL(fileURLWithPath: #filePath)
    let packageRoot =
      testFile
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()

    return
      packageRoot
      .deletingLastPathComponent()
      .appending(path: "BookishImporter")
      .appending(path: "Sources")
      .appending(path: "BookishImporterSamples")
      .appending(path: "Resources")
      .appending(path: "DeliciousSmall.xml")
  }
}
