// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import FoundationModels

/// A possible identification of a book visible in an image.
@Generable(description: "One book that can be identified from supplied OCR text.")
public struct BookRecognitionCandidate: Codable, Equatable, Identifiable, Sendable {
  /// A stable identifier for display while the recognition result is in memory.
  public var id: String { "\(title)|\(authors.joined(separator: ","))" }

  /// The title read from the book or inferred from its visible cover or spine.
  public let title: String

  /// The authors identified for the book.
  public let authors: [String]

  /// The model's self-reported confidence from zero to one.
  public let confidence: Double

  /// Creates a book-recognition candidate.
  public init(title: String, authors: [String], confidence: Double) {
    self.title = title
    self.authors = authors
    self.confidence = confidence
  }
}

@Generable(description: "Book identification candidates that are supported by supplied OCR text.")
public struct BookRecognitionResult: Codable {
  /// Candidate books visible in the source text.
  public var candidates: [BookRecognitionCandidate]
}
