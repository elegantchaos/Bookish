// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCapture
import Foundation

/// Defines the book-recognition state and actions used by the application's UI.
@MainActor
public protocol BookishRecognition {
  /// The candidate books returned by the selected recognizer.
  var candidates: [BookRecognitionCandidate] { get }

  /// The identifiers of candidates selected for addition.
  var selectedCandidateIDs: Set<String> { get }

  /// Whether the datastore can accept recognised books.
  var canAddBooks: Bool { get }

  /// Whether book recognition is currently underway.
  var isRecognizing: Bool { get }

  /// Whether the workflow has an image to recognise.
  var hasImage: Bool { get }

  /// Whether the selected recognizer can run on this device.
  var isCurrentRecognizerSupported: Bool { get }

  var selectedRecognizerID: BookRecognizerID { get }

  /// Selects a recognizer by its identifier.
  func selectRecognizer(_ recognizerID: BookRecognizerID)
  
  /// Returns whether the recognizer identified by `id` can run on this device.
  func isRecognizerSupported(_ id: BookRecognizerID) -> Bool

  /// Replaces the image to recognise.
  func selectImage(data: Data?)

  /// Selects all displayed candidates.
  func selectAllCandidates()

  /// Identifies books in the selected image.
  func identifyBooks() async

  /// Adds the selected candidates to the catalogue.
  func addSelectedBooks() async throws

  /// Clears the selected candidates.
  func deselectAllCandidates()

  /// Selects the bundled demonstration image.
  func selectCaptureGoodExample()
}
