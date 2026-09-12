// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCapture
import BookishRecord
import Foundation
import Observation

@MainActor
public protocol BookishRecognition {
  var candidates: [BookRecognitionCandidate] { get }
  var selectedCandidateIDs: Set<String> { get }
  var canAddBooks: Bool { get }
  var isRecognizing: Bool { get }

  func selectRecognizer(_ id: String) async
  func selectImage(data: Data?)
  func selectAllCandidates()
  func identifyBooks() async
  func addSelectedBooks() async throws
  func deselectAllCandidates()
  func selectCaptureGoodExample()
}

/// Persists recognised candidates as new book records and refreshes the browser projection.
@MainActor
@Observable
public final class BookishRecognitionService: BookishRecognition {
  /// The storage service used to persist new records.
  private unowned let storage: BookishStorageService

  /// The UI state refreshed after records are added.
  private unowned let state: BookishUIStateService

  /// The status service used to report successful additions.
  private let statusService: any BookishStatus

  private let serviceFactory: BookRecognizerRegistry

  public var recognizerID: String {
    didSet {
      recognizer = serviceFactory.recognizer(for: recognizerID)
    }
  }

  public var recognizer: any BookRecognizer

  /// The data selected by the user for recognition.
  public private(set) var imageData: Data?

  /// Candidate books returned by the recognizer.
  public private(set) var candidates: [BookRecognitionCandidate]

  /// The candidate identifiers selected for addition.
  public var selectedCandidateIDs: Set<String>

  /// A recognition error suitable for display.
  public private(set) var error: (any Error)?

  /// Whether a request is currently underway.
  public private(set) var isRecognizing: Bool

  /// Creates a record-adder with application-owned services.
  init(
    storage: BookishStorageService,
    state: BookishUIStateService,
    statusService: any BookishStatus
  ) {
    let factory = BookRecognizerRegistry()
    factory.registerDefaultRecognizers()
    let defaultID = factory.recognizerIDs.first!

    self.storage = storage
    self.state = state
    self.statusService = statusService
    self.serviceFactory = factory

    imageData = nil
    candidates = []
    selectedCandidateIDs = []
    error = nil
    isRecognizing = false
    recognizerID = defaultID
    recognizer = serviceFactory.recognizer(for: defaultID)
  }

  public var recognizerIDs: [String] {
    serviceFactory.recognizerIDs
  }

  public var recognizers: [any BookRecognizer] {
    serviceFactory.recognizers
  }

  /// Whether the datastore has completed loading.
  public var canAddBooks: Bool {
    storage.isLoaded
  }

  /// Replaces the selected image and clears the preceding result.
  public func selectImage(data: Data?) {
    imageData = data
    candidates = []
    selectedCandidateIDs = []
    error = nil
  }

  /// Selects a recognizer and identifies the current image when the provider changes.
  public func selectRecognizer(_ id: String) async {
    self.recognizer = serviceFactory.recognizer(for: id)
    await identifyBooks()
  }

  /// Selects the app's bundled image for trying book recognition.
  public func selectCaptureGoodExample() {
    do {
      selectImage(data: try CaptureGoodExample.load())
    } catch {
      selectImage(data: nil)
      self.error = error
    }
  }

  /// Requests identifications for the selected image.
  public func identifyBooks() async {
    guard let imageData else { return }
    isRecognizing = true
    error = nil
    defer { isRecognizing = false }

    do {
      candidates = try await recognizer.identifyBooks(in: imageData)
      selectedCandidateIDs = []
    } catch {
      self.error = error
    }
  }

  /// Adds the candidates selected in the scanning list.
  public func addSelectedBooks() async throws {
    let selectedCandidates = candidates.filter {
      selectedCandidateIDs.contains($0.id)
    }
    try await addBooks(selectedCandidates)
  }

  /// Selects every candidate currently shown in the scanning list.
  public func selectAllCandidates() {
    selectedCandidateIDs = Set(candidates.map(\.id))
  }

  /// Clears the selection in the scanning list.
  public func deselectAllCandidates() {
    selectedCandidateIDs = []
  }

  /// Adds candidates and removes only those successfully persisted from the workflow.
  private func addBooks(_ candidates: [BookRecognitionCandidate]) async throws {
    guard candidates.isEmpty == false else { return }
    try await storage.upsert(records: candidates.map(\.bookRecord))
    try await state.refreshBrowser()
    statusService.report(
      message:
        "Added \(candidates.count) \(candidates.count == 1 ? "book" : "books")"
    )

    let addedIDs = Set(candidates.map(\.id))
    self.candidates.removeAll { addedIDs.contains($0.id) }
    selectedCandidateIDs.subtract(addedIDs)
  }
}
extension BookRecognitionCandidate {
  /// Builds the initial catalogue record for a recognised book.
  var bookRecord: BookishRecord {
    BookishRecord(
      kind: BookishRecordKind.book,
      properties: [BookishRecordKey.name: .string(title)]
    )
  }
}

/// Performs the HTTP request required by a book recognizer.
public protocol BookRecognitionTransport: Sendable {
  /// Loads the data for a URL request.
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: BookRecognitionTransport {
}

/// Loads the shelf image bundled with Bookish for recognition demonstrations.
private enum CaptureGoodExample {
  /// Loads the bundled image data.
  static func load() throws -> Data {
    guard
      let url = Bundle.module.url(
        forResource: "CaptureGoodExample",
        withExtension: "JPG"
      )
    else {
      throw BookRecognitionError.captureGoodExampleUnavailable
    }

    do {
      return try Data(contentsOf: url)
    } catch {
      throw BookRecognitionError.captureGoodExampleUnavailable
    }
  }
}
