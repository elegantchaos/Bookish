import BookishCoding
import Foundation

/// Imports materialised-record Bookish interchange documents.
public struct BookishInterchangeImporter: BookishImporter {
  /// Stable identifier for Bookish interchange documents.
  public static let sourceID = "com.elegantchaos.bookish.importer.interchange"

  /// The number of records included in each emitted batch.
  public static let batchSize = 64

  /// Creates an interchange importer.
  public init() {
  }

  /// Metadata used by import coordinators and user interfaces.
  public var descriptor: BookishImporterDescriptor {
    BookishImporterDescriptor(sourceID: Self.sourceID, displayName: "Bookish interchange")
  }

  /// Imports records from interchange JSON data.
  public func importEvents(from data: Data) -> AsyncThrowingStream<BookishImportEvent, Error> {
    let (stream, continuation) = AsyncThrowingStream.makeStream(
      of: BookishImportEvent.self,
      throwing: Error.self
    )
    let importer = self

    let task = Task {
      do {
        continuation.yield(.started(BookishImportStart(importer: importer.descriptor)))
        let file = try BookishInterchangeCodec().decode(data)
        let total = file.records.count
        continuation.yield(
          .progress(
            BookishImportProgress(
              message: "Importing Bookish interchange", completed: 0, total: total)))

        var imported = 0
        for records in file.records.chunked(into: Self.batchSize) {
          try Task.checkCancellation()
          continuation.yield(.records(records))
          imported += records.count
          continuation.yield(
            .progress(
              BookishImportProgress(
                message: "Importing Bookish interchange", completed: imported, total: total)))
          await Task.yield()
        }

        continuation.yield(
          .finished(
            BookishImportSummary(sourceID: Self.sourceID, root: file.root, recordCount: imported)))
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
}

extension Array {
  fileprivate func chunked(into size: Int) -> [[Element]] {
    stride(from: 0, to: count, by: size).map { start in
      Array(self[start..<Swift.min(start + size, count)])
    }
  }
}
