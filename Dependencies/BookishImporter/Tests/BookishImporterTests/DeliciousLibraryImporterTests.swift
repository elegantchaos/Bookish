import BookishCoding
import BookishImporterSamples
import BookishRecord
import Foundation
import Testing

@testable import BookishImporter

struct DeliciousLibraryImporterTests {
  @Test
  func importsDeliciousSmallAsNormalisedGraph() throws {
    let result = try DeliciousLibraryImporter().importRecords(from: deliciousSampleURL())

    #expect(result.sourceID == DeliciousLibraryImporter.sourceID)
    #expect(result.root == BookishRecordID("delicious-import"))
    #expect(result.diagnostics.isEmpty)

    let recordsByID = Dictionary(uniqueKeysWithValues: result.records.map { ($0.id, $0) })
    let snowCrash = try #require(
      result.records.first { $0.string(BookishRecordKey.name) == "Snow Crash" && $0.kind == "book" }
    )

    #expect(snowCrash.string("isbn") == "0140232923")
    #expect(snowCrash.integer("pages") == 448)
    #expect(snowCrash.string("source") == DeliciousLibraryImporter.sourceID)
    #expect(snowCrash.list("imageURLs")?.count == 3)
    #expect(snowCrash.string(BookishRecordKey.image) == snowCrash.strings(BookishRecordKey.imageURLs)?.first)

    let originalData = try #require(snowCrash.string(BookishRecordKey.originalData))
    let originalRecord = try #require(
      JSONSerialization.jsonObject(with: Data(originalData.utf8)) as? [String: Any]
    )
    #expect(originalRecord["title"] as? String == "Snow Crash")
    #expect(originalRecord["creationDate"] as? String == "2004-11-29T13:09:36Z")
    #expect(snowCrash.properties.keys.contains("original.name") == false)
    #expect(snowCrash.properties.keys.contains("original.subtitle") == false)
    #expect(snowCrash.properties.keys.contains("original.publishers") == false)
    #expect(snowCrash.properties.keys.contains("original.series") == false)
    #expect(snowCrash.properties.keys.contains("original.seriesPosition") == false)

    let authorID = try #require(snowCrash.list("authors")?.first?.recordValue)
    let author = try #require(recordsByID[authorID])
    #expect(author.kind == "person")
    #expect(author.string("name") == "Neal Stephenson")

    let publisherID = try #require(snowCrash.list("publishers")?.first?.recordValue)
    let publisher = try #require(recordsByID[publisherID])
    #expect(publisher.kind == "organisation")
    #expect(publisher.string("name") == "RoC")

    let illustratedBook = try #require(
      result.records.first {
        $0.kind == "book" && $0.list(BookishRecordKey.illustrators)?.isEmpty == false
      }
    )
    let illustratorID = try #require(
      illustratedBook.list(BookishRecordKey.illustrators)?.first?.recordValue
    )
    #expect(recordsByID[illustratorID]?.kind == "person")

    for key in [
      BookishRecordKey.authors,
      BookishRecordKey.illustrators,
      BookishRecordKey.publishers,
    ] {
      let relationshipValues = result.records
        .filter { $0.kind == "book" }
        .compactMap { $0.list(key) }
        .flatMap { $0 }

      #expect(relationshipValues.allSatisfy { $0.recordValue != nil })
    }

    #expect(result.records.contains { $0.kind == "relationship" } == false)
  }

  @Test

  func importsSeriesRecordsAndDirectReference() throws {
    let result = try DeliciousLibraryImporter().importRecords(from: deliciousSampleURL())
    let gameOfThrones = try #require(
      result.records.first {
        $0.string(BookishRecordKey.name) == "A Game of Thrones" && $0.kind == "book"
      })

    let seriesID = try #require(gameOfThrones.record("series"))
    let series = try #require(result.records.first { $0.id == seriesID })

    #expect(series.kind == "series")
    #expect(series.string("name") == "A Song of Ice and Fire")
    #expect(gameOfThrones.integer("seriesPosition") == 1)
  }

  @Test

  func importIsDeterministic() throws {
    let importer = DeliciousLibraryImporter()
    let first = try importer.importRecords(from: deliciousSampleURL())
    let second = try importer.importRecords(from: deliciousSampleURL())

    #expect(first == second)
  }

  @Test

  func importedRecordsRoundTripThroughInterchangeCoding() throws {
    let result = try DeliciousLibraryImporter().importRecords(from: deliciousSampleURL())
    let file = BookishInterchangeFile(root: result.root, records: result.records)
    let data = try BookishInterchangeCodec(recordLinkEncoding: .shorthand).encode(file)
    let decoded = try BookishInterchangeCodec().decode(data)

    #expect(decoded.root == result.root)
    #expect(decoded.records == result.records)
  }

  private func deliciousSampleURL() throws -> URL {
    try BookishImporterSamples.deliciousLibraryURL(for: .small)
  }
}
