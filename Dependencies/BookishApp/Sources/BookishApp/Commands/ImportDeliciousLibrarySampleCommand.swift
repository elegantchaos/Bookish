// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import BookishImporterSamples
import CommandsUI
import Foundation
import Icons

/// Imports one of Bookish's bundled Delicious Library samples.
public struct ImportDeliciousLibrarySampleCommand: CommandWithUI {
  public typealias Centre = BookishHarness
  public typealias ResultType = Void

  /// The bundled sample to import.
  public let sample: DeliciousLibrarySample

  /// Creates a command for a bundled Delicious Library sample.
  public init(sample: DeliciousLibrarySample) {
    self.sample = sample
  }

  public var id: String {
    "datastore.import.delicious-library.\(sample.rawValue)"
  }

  public func name(centre: BookishHarness) -> String {
    switch sample {
    case .small:
      "Small Sample"
    case .full:
      "Full Sample"
    }
  }

  public func icon(centre: BookishHarness) -> Icon {
    Icon("books.vertical")
  }

  public func help(centre: BookishHarness) -> String? {
    "Import the bundled \(name(centre: centre)) Delicious Library XML export."
  }

  public func perform(centre: BookishHarness) async throws {
    await centre.importDeliciousLibrary(sample: sample)
  }
}
