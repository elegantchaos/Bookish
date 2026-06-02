import BookishRecord
import Foundation
import XCTest

@testable import BookishDatastore

final class DatastorePrototypeTests: XCTestCase {
  func testMutationServiceAppliesPropertyMutationToRecordStore() async throws {
    let prototype = try await makePrototype()
    let bookID = BookishRecordID("book-1")

    try await prototype.mutationService.perform(
      .setProperty(
        recordID: bookID, kind: "book", key: "title", value: .string("The Left Hand of Darkness"))
    )

    let record = try await prototype.recordService.record(id: bookID)
    XCTAssertEqual(record?.kind, "book")
    XCTAssertEqual(record?.string("title"), "The Left Hand of Darkness")
  }

  func testMutationServiceDoesNotApplySameRemoteMutationTwice() async throws {
    let prototype = try await makePrototype()
    let bookID = BookishRecordID("book-1")
    let mutation = MutationRecord(
      id: MutationID("remote-1"),
      operation: .setProperty(
        recordID: bookID, kind: "book", key: "title", value: .string("Original"))
    )

    try await prototype.mutationService.receiveRemoteMutation(mutation)
    try await prototype.mutationService.receiveRemoteMutation(mutation)

    let mutations = try await prototype.mutationStore.mutations()
    let record = try await prototype.recordService.record(id: bookID)
    XCTAssertEqual(mutations, [mutation])
    XCTAssertEqual(record?.string("title"), "Original")
  }

  func testJSONStoresReloadPersistedData() async throws {
    let directory = try temporaryDirectory()
    let prototype = try await DatastorePrototype(directoryURL: directory)
    let bookID = BookishRecordID("book-1")

    try await prototype.mutationService.perform(
      .setProperty(recordID: bookID, kind: "book", key: "title", value: .string("Persisted"))
    )

    let reloaded = try await DatastorePrototype(directoryURL: directory)
    try await reloaded.mutationService.processPendingMutations()

    let record = try await reloaded.recordService.record(id: bookID)
    XCTAssertEqual(record?.string("title"), "Persisted")
  }

  func testRecordStoreRemoveAllClearsPersistedRecords() async throws {
    let directory = try temporaryDirectory()
    let prototype = try await DatastorePrototype(directoryURL: directory)
    let bookID = BookishRecordID("book-1")

    try await prototype.recordStore.upsert(
      BookishRecord(id: bookID, kind: "book", properties: ["title": .string("Persisted")])
    )

    try await prototype.recordStore.removeAll()

    let reloaded = try await DatastorePrototype(directoryURL: directory)
    let records = try await reloaded.recordService.records()
    XCTAssertTrue(records.isEmpty)
  }

  func testMutationStoreRemoveAllClearsPersistedMutations() async throws {
    let directory = try temporaryDirectory()
    let prototype = try await DatastorePrototype(directoryURL: directory)
    let bookID = BookishRecordID("book-1")

    try await prototype.mutationService.perform(
      .setProperty(recordID: bookID, kind: "book", key: "title", value: .string("Persisted"))
    )

    try await prototype.mutationStore.removeAll()

    let reloaded = try await DatastorePrototype(directoryURL: directory)
    let mutations = try await reloaded.mutationStore.mutations()
    XCTAssertTrue(mutations.isEmpty)
  }

  private func makePrototype() async throws -> DatastorePrototype {
    try await DatastorePrototype(directoryURL: temporaryDirectory())
  }

  private func temporaryDirectory() throws -> URL {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }
}
