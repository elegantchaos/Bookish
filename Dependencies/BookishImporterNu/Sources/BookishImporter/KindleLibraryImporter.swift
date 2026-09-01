import Foundation

/// A future source location for Kindle library extraction.
public struct KindleLibrarySource: Equatable, Sendable {
  /// The location from which a Kindle library will be extracted.
  public var url: URL

  /// Creates a Kindle library source.
  public init(url: URL) {
    self.url = url
  }
}

/// Placeholder for Kindle library importing while its extraction mechanism is designed.
public struct KindleLibraryImporter: BookishImporter {
  /// Stable identifier reserved for Kindle library imports.
  public static let sourceID = "com.elegantchaos.bookish.importer.kindle-library"

  /// Creates a Kindle library importer.
  public init() {
  }

  /// Metadata used by import coordinators and user interfaces.
  public var descriptor: BookishImporterDescriptor {
    BookishImporterDescriptor(sourceID: Self.sourceID, displayName: "Kindle library")
  }

  /// Reports that Kindle extraction has not been implemented yet.
  public func importEvents(from source: KindleLibrarySource) -> AsyncThrowingStream<
    BookishImportEvent, Error
  > {
    let (stream, continuation) = AsyncThrowingStream.makeStream(
      of: BookishImportEvent.self,
      throwing: Error.self
    )

    continuation.yield(.started(BookishImportStart(importer: descriptor)))
    continuation.finish(
      throwing: BookishImportError.unavailable("Kindle library import is not available yet."))
    return stream
  }
}
