import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// A JSON file document used to export datastore interchange data.
public struct BookishInterchangeDocument: FileDocument {
  public static var readableContentTypes: [UTType] {
    [.json]
  }

  public static var writableContentTypes: [UTType] {
    [.json]
  }

  /// The raw JSON payload.
  public var data: Data

  /// Creates an interchange document.
  public init(data: Data = Data()) {
    self.data = data
  }

  /// Reads an interchange document from a file wrapper.
  public init(configuration: ReadConfiguration) throws {
    self.data = configuration.file.regularFileContents ?? Data()
  }

  /// Writes the interchange document to a file wrapper.
  public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
    FileWrapper(regularFileWithContents: data)
  }
}
