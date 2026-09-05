// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// A Delicious Library sample bundled with Bookish for sample-data testing.
public enum DeliciousLibrarySample: String, Sendable {
  /// The compact Delicious Library sample.
  case small

  /// The larger Delicious Library sample.
  case full

  fileprivate var resourceName: String {
    switch self {
    case .small:
      "DeliciousSmall"
    case .full:
      "DeliciousFull"
    }
  }
}

/// Errors raised while locating a bundled import sample.
public enum BookishImporterSampleError: Error, Equatable, LocalizedError {
  /// The named bundled sample could not be located.
  case missingBundledSample(String)

  /// A user-facing explanation of the sample lookup failure.
  public var errorDescription: String? {
    switch self {
    case .missingBundledSample(let name):
      "The bundled import sample \(name) could not be found."
    }
  }
}

/// Provides URLs for import sample files bundled with the modern importer.
public enum BookishImporterSamples {
  /// Returns the bundled XML file for a Delicious Library sample.
  public static func deliciousLibraryURL(for sample: DeliciousLibrarySample) throws -> URL {
    guard let url = Bundle.module.url(forResource: sample.resourceName, withExtension: "xml") else {
      throw BookishImporterSampleError.missingBundledSample(sample.resourceName)
    }
    return url
  }
}
