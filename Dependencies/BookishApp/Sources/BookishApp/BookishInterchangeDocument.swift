// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/10/2022.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import SwiftUI
import UniformTypeIdentifiers

/// A JSON file document used to export datastore interchange data.
public struct BookishInterchangeDocument: FileDocument {
  /// The file types this document can import.
  public static var readableContentTypes: [UTType] {
    [.json]
  }

  /// The file types this document can export.
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
