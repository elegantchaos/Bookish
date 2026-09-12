// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

/// Returns deterministic candidates for exercising the scanning workflow without a live provider.
public struct FakeBookRecognizer: BookRecognizer {
  public let id = "com.elegantchaos.bookish.recognizer.fake"
  public let label = "Fake"
  public let description =
    "Returns a fixed sample of books without processing the selected image."

  /// Creates the fake recognizer.
  public init() {
  }

  /// Returns sample candidates without reading the supplied image data.
  public func identifyBooks(in _: Data) async throws
    -> [BookRecognitionCandidate]
  {
    Self.sampleCandidates
  }

  /// The candidates returned on every request.
  public static let sampleCandidates = [
    BookRecognitionCandidate(
      title: "The Left Hand of Darkness",
      authors: ["Ursula K. Le Guin"],
      confidence: 0.99
    ),
    BookRecognitionCandidate(
      title: "A Fire Upon the Deep",
      authors: ["Vernor Vinge"],
      confidence: 0.97
    ),
    BookRecognitionCandidate(
      title: "The Fifth Season",
      authors: ["N. K. Jemisin"],
      confidence: 0.96
    ),
  ]
}
