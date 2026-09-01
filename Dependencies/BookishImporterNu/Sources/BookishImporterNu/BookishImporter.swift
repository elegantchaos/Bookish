import BookishRecord
import Foundation

/// Describes an importer to a user-facing import coordinator.
public struct BookishImporterDescriptor: Equatable, Sendable {
  /// The stable identifier for the importer.
  public var sourceID: String

  /// The name displayed while importing.
  public var displayName: String

  /// Creates an importer descriptor.
  public init(sourceID: String, displayName: String) {
    self.sourceID = sourceID
    self.displayName = displayName
  }
}

/// Announces the beginning of an import.
public struct BookishImportStart: Equatable, Sendable {
  /// The importer producing the events.
  public var importer: BookishImporterDescriptor

  /// The expected number of source items, when known.
  public var total: Int?

  /// Creates a start event.
  public init(importer: BookishImporterDescriptor, total: Int? = nil) {
    self.importer = importer
    self.total = total
  }
}

/// Describes the importer’s current progress through its source data.
public struct BookishImportProgress: Equatable, Sendable {
  /// A short explanation of the work currently underway.
  public var message: String

  /// The number of source items processed so far.
  public var completed: Int

  /// The total number of source items, when known.
  public var total: Int?

  /// Creates a progress update.
  public init(message: String, completed: Int, total: Int? = nil) {
    self.message = message
    self.completed = completed
    self.total = total
  }
}

/// Summarises a completed import without retaining every emitted record.
public struct BookishImportSummary: Equatable, Sendable {
  /// The importer that produced the result.
  public var sourceID: String

  /// The root record for the imported graph, when one exists.
  public var root: BookishRecordID?

  /// The number of records emitted by the importer.
  public var recordCount: Int

  /// Non-fatal messages produced while importing.
  public var diagnostics: [String]

  /// Creates an import summary.
  public init(
    sourceID: String,
    root: BookishRecordID? = nil,
    recordCount: Int,
    diagnostics: [String] = []
  ) {
    self.sourceID = sourceID
    self.root = root
    self.recordCount = recordCount
    self.diagnostics = diagnostics
  }
}

/// A value produced by a streaming Bookish importer.
public enum BookishImportEvent: Equatable, Sendable {
  /// The import has begun. This is the first successful event from an importer.
  case started(BookishImportStart)

  /// The importer has made progress through its source data.
  case progress(BookishImportProgress)

  /// Materialised records ready for idempotent upsert by the consumer.
  case records([BookishRecord])

  /// A non-fatal issue encountered while importing.
  case diagnostic(String)

  /// The import has completed successfully.
  case finished(BookishImportSummary)
}

/// Converts one source representation into a stream of normalised Bookish records.
public protocol BookishImporter<Input>: Sendable where Input: Sendable {
  associatedtype Input: Sendable

  /// Stable metadata used by import coordinators and user interfaces.
  var descriptor: BookishImporterDescriptor { get }

  /// Produces ordered import lifecycle, progress, and record events.
  func importEvents(from input: Input) -> AsyncThrowingStream<BookishImportEvent, Error>
}
