import BookishRecord
import Foundation
import Testing

@testable import BookishDatastore

struct BookishDatastoreTests {
  private struct LegacyMutationState: Codable {
    var mutations: [MutationRecord]
    var applied: Set<MutationID>
  }

  @Test

  func mutationServiceAppliesPropertyMutationToRecordStore() async throws {
    let datastore = try await makeDatastore()
    let bookID = BookishRecordID("book-1")

    try await datastore.mutationService.perform(
      .setProperty(
        recordID: bookID, kind: "book", key: "title", value: .string("The Left Hand of Darkness"))
    )

    let record = try await datastore.recordService.record(id: bookID)
    #expect(record?.kind == "book")
    #expect(record?.string("title") == "The Left Hand of Darkness")
  }

  @Test

  func mutationServiceDoesNotApplySameRemoteMutationTwice() async throws {
    let datastore = try await makeDatastore()
    let bookID = BookishRecordID("book-1")
    let mutation = MutationRecord(
      id: MutationID("remote-1"),
      operation: .setProperty(
        recordID: bookID, kind: "book", key: "title", value: .string("Original"))
    )

    try await datastore.mutationService.receiveRemoteMutation(mutation)
    try await datastore.mutationService.receiveRemoteMutation(mutation)

    let mutations = try await datastore.mutationStore.mutations()
    let record = try await datastore.recordService.record(id: bookID)
    #expect(mutations == [mutation])
    #expect(record?.string("title") == "Original")
  }

  @Test

  func jSONStoresReloadPersistedData() async throws {
    let directory = try temporaryDirectory()
    let datastore = try await BookishDatastore(directoryURL: directory)
    let bookID = BookishRecordID("book-1")

    try await datastore.mutationService.perform(
      .setProperty(recordID: bookID, kind: "book", key: "title", value: .string("Persisted"))
    )

    let reloaded = try await BookishDatastore(directoryURL: directory)
    try await reloaded.mutationService.processPendingMutations()

    let record = try await reloaded.recordService.record(id: bookID)
    #expect(record?.string("title") == "Persisted")
  }

  @Test

  func recordStoreRemoveAllClearsPersistedRecords() async throws {
    let directory = try temporaryDirectory()
    let datastore = try await BookishDatastore(directoryURL: directory)
    let bookID = BookishRecordID("book-1")

    try await datastore.recordStore.upsert(
      BookishRecord(id: bookID, kind: "book", properties: ["title": .string("Persisted")])
    )

    try await datastore.recordStore.removeAll()

    let reloaded = try await BookishDatastore(directoryURL: directory)
    let records = try await reloaded.recordService.records()
    #expect(records.isEmpty)
  }

  @Test

  func recordStoreOnlyRewritesTheChangedRecordFile() async throws {
    let directory = try temporaryDirectory().appending(path: "records", directoryHint: .isDirectory)
    let store = try await JSONRecordStore(directoryURL: directory)
    let first = BookishRecord(
      id: BookishRecordID("book-1"), kind: "book", properties: ["title": .string("First")])
    let second = BookishRecord(
      id: BookishRecordID("book-2"), kind: "book", properties: ["title": .string("Second")])

    try await store.upsert(first)
    try await store.upsert(second)
    let secondFile = try file(containing: second, in: directory)
    let unchangedData = try Data(contentsOf: secondFile)

    try await store.upsert(
      BookishRecord(
        id: first.id, kind: first.kind, properties: ["title": .string("Updated")]))

    #expect(try Data(contentsOf: secondFile) == unchangedData)
    #expect(try recordFiles(in: directory).count == 2)
    let updated = try await store.record(id: first.id)
    #expect(updated?.string("title") == "Updated")
  }

  @Test

  func recordStoreMigratesLegacySingleFileProjection() async throws {
    let parentDirectory = try temporaryDirectory()
    let legacyFile = parentDirectory.appending(path: "records.json")
    let legacyRecord = BookishRecord(
      id: BookishRecordID("legacy-book"), kind: "book", properties: ["title": .string("Legacy")])
    try JSONEncoder().encode([legacyRecord]).write(to: legacyFile)

    let recordsDirectory = parentDirectory.appending(path: "records", directoryHint: .isDirectory)
    let store = try await JSONRecordStore(directoryURL: recordsDirectory)

    let migratedRecord = try await store.record(id: legacyRecord.id)
    #expect(migratedRecord == legacyRecord)
    #expect(try recordFiles(in: recordsDirectory).count == 1)
    #expect(FileManager.default.fileExists(atPath: legacyFile.path))
  }

  @Test

  func recordServiceReturnsRecordIDsInStableOrder() async throws {
    let datastore = try await makeDatastore()
    let secondID = BookishRecordID("book-2")
    let firstID = BookishRecordID("book-1")

    try await datastore.recordStore.upsert(BookishRecord(id: secondID, kind: "book"))
    try await datastore.recordStore.upsert(BookishRecord(id: firstID, kind: "book"))

    let ids = try await datastore.recordService.recordIDs()

    #expect(ids == [firstID, secondID])
  }

  @Test

  func recordServiceFiltersRecordIDsWithPredicate() async throws {
    let datastore = try await makeDatastore()
    let bookID = BookishRecordID("book-1")
    let authorID = BookishRecordID("author-1")

    try await datastore.recordStore.upsert(BookishRecord(id: authorID, kind: "author"))
    try await datastore.recordStore.upsert(
      BookishRecord(id: bookID, kind: "book", properties: ["status": .string("Reading")])
    )

    let ids = try await datastore.recordService.recordIDs(
      matching: .and([.kind("book"), .property("status", equals: .string("Reading"))])
    )

    #expect(ids == [bookID])
  }

  @Test

  func recordQueryFiltersAndSortsRecords() async throws {
    let datastore = try await makeDatastore()
    let first = BookishRecord(
      id: BookishRecordID("book-1"),
      kind: "book",
      properties: ["title": .string("Zen and the Art of Motorcycle Maintenance")]
    )
    let second = BookishRecord(
      id: BookishRecordID("book-2"),
      kind: "book",
      properties: ["title": .string("A Wizard of Earthsea")]
    )
    let author = BookishRecord(id: BookishRecordID("author-1"), kind: "person")

    try await datastore.recordStore.upsert(first)
    try await datastore.recordStore.upsert(second)
    try await datastore.recordStore.upsert(author)

    let records = try await datastore.recordService.records(
      matching: RecordQuery(
        predicate: .kind("book"),
        sort: [.property(BookishRecordKey.title), .id]
      ))

    #expect(records.map(\.id) == [second.id, first.id])
  }

  @Test

  func recordQueryCanMatchRecordReferencesInListProperties() async throws {
    let datastore = try await makeDatastore()
    let authorID = BookishRecordID("author-1")
    let matching = BookishRecord(
      id: BookishRecordID("book-1"),
      kind: "book",
      properties: [BookishRecordKey.authors: .list([.record(authorID)])]
    )
    let other = BookishRecord(
      id: BookishRecordID("book-2"),
      kind: "book",
      properties: [BookishRecordKey.authors: .list([.record(BookishRecordID("author-2"))])]
    )

    try await datastore.recordStore.upsert(other)
    try await datastore.recordStore.upsert(matching)

    let records = try await datastore.recordService.records(
      matching: RecordQuery(
        predicate: .and([
          .kind("book"),
          .propertyContains(BookishRecordKey.authors, .record(authorID)),
        ])
      ))

    #expect(records.map(\.id) == [matching.id])
  }

  @Test

  func recordQueryResultRefreshesAfterMutation() async throws {
    let datastore = try await makeDatastore()
    let result = try await datastore.recordQueryService.result(
      matching: RecordQuery(
        predicate: .kind("book"),
        sort: [.property(BookishRecordKey.title), .id]
      ))

    let initialRecords = await MainActor.run { result.records }
    #expect(initialRecords.isEmpty)

    let book = BookishRecord(
      id: BookishRecordID("book-1"),
      kind: "book",
      properties: [BookishRecordKey.title: .string("A Wizard of Earthsea")]
    )
    try await datastore.mutationService.perform(.upsertRecord(book))

    let updatedRecords = await MainActor.run { result.records }
    #expect(updatedRecords == [book])
  }

  @Test

  func recordQueryServiceReusesEquivalentResults() async throws {
    let datastore = try await makeDatastore()
    let query = RecordQuery(predicate: .kind("book"), sort: [.id])

    let first = try await datastore.recordQueryService.result(matching: query)
    let second = try await datastore.recordQueryService.result(matching: query)

    #expect(first === second)
  }

  @Test

  func mutationStoreRemoveAllClearsPersistedMutations() async throws {
    let directory = try temporaryDirectory()
    let datastore = try await BookishDatastore(directoryURL: directory)
    let bookID = BookishRecordID("book-1")

    try await datastore.mutationService.perform(
      .setProperty(recordID: bookID, kind: "book", key: "title", value: .string("Persisted"))
    )

    try await datastore.mutationStore.removeAll()

    let reloaded = try await BookishDatastore(directoryURL: directory)
    let mutations = try await reloaded.mutationStore.mutations()
    #expect(mutations.isEmpty)
  }

  @Test

  func mutationStoreOnlyWritesNewMutationFiles() async throws {
    let directory = try temporaryDirectory().appending(
      path: "mutations", directoryHint: .isDirectory)
    let store = try await JSONMutationStore(directoryURL: directory)
    let first = MutationRecord(
      id: MutationID("mutation-1"), operation: .deleteRecord(BookishRecordID("book-1")))
    let second = MutationRecord(
      id: MutationID("mutation-2"), operation: .deleteRecord(BookishRecordID("book-2")))

    try await store.append(first)
    let firstFile = try file(containing: first, in: directory.appending(path: "records"))
    let unchangedData = try Data(contentsOf: firstFile)

    try await store.append(second)
    try await store.markApplied(first.id)

    #expect(try Data(contentsOf: firstFile) == unchangedData)
    #expect(try mutationFiles(in: directory.appending(path: "records")).count == 2)
    #expect(try markerFiles(in: directory.appending(path: "applied")).count == 1)
  }

  @Test

  func mutationStoreMigratesLegacySingleFileLog() async throws {
    let parentDirectory = try temporaryDirectory()
    let legacyFile = parentDirectory.appending(path: "mutations.json")
    let mutation = MutationRecord(
      id: MutationID("legacy-mutation"),
      operation: .deleteRecord(BookishRecordID("legacy-book")),
      createdAt: Date(timeIntervalSinceReferenceDate: 0))
    let legacyState = LegacyMutationState(mutations: [mutation], applied: [mutation.id])
    try JSONEncoder.bookishDatastoreEncoder().encode(legacyState).write(to: legacyFile)

    let directory = parentDirectory.appending(path: "mutations", directoryHint: .isDirectory)
    let store = try await JSONMutationStore(directoryURL: directory)

    let migratedMutations = try await store.mutations()
    let isApplied = try await store.isApplied(mutation.id)
    #expect(migratedMutations == [mutation])
    #expect(isApplied)
    #expect(try mutationFiles(in: directory.appending(path: "records")).count == 1)
    #expect(try markerFiles(in: directory.appending(path: "applied")).count == 1)
    #expect(FileManager.default.fileExists(atPath: legacyFile.path))
  }

  private func makeDatastore() async throws -> BookishDatastore {
    try await BookishDatastore(directoryURL: temporaryDirectory())
  }

  private func temporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }

  private func recordFiles(in directory: URL) throws -> [URL] {
    try FileManager.default.contentsOfDirectory(
      at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
  }

  private func file(containing record: BookishRecord, in directory: URL) throws -> URL {
    let files = try recordFiles(in: directory)
    return try #require(
      files.first { file in
        guard
          let data = try? Data(contentsOf: file),
          let decoded = try? JSONDecoder().decode(BookishRecord.self, from: data)
        else {
          return false
        }
        return decoded == record
      })
  }

  private func mutationFiles(in directory: URL) throws -> [URL] {
    try FileManager.default.contentsOfDirectory(
      at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
  }

  private func markerFiles(in directory: URL) throws -> [URL] {
    try FileManager.default.contentsOfDirectory(
      at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
  }

  private func file(containing mutation: MutationRecord, in directory: URL) throws -> URL {
    let files = try mutationFiles(in: directory)
    return try #require(
      files.first { file in
        guard
          let data = try? Data(contentsOf: file),
          let decoded = try? JSONDecoder.bookishDatastoreDecoder().decode(
            MutationRecord.self, from: data)
        else {
          return false
        }
        return decoded.id == mutation.id
      })
  }
}
