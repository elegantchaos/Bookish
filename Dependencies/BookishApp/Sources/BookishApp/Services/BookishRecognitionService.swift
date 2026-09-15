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
  var hasImage: Bool { get }
  var isCurrentRecognizerSupported: Bool { get }

  func selectRecognizer(_ id: String) async
  func isRecognizerSupported(_ id: String) -> Bool
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

  /// The app preference that remembers the selected recognizer.
  private let methodPreference: BookRecognitionMethodPreference

  /// The identifier of the recognizer selected for the current and future captures.
  public private(set) var recognizerID: String {
    didSet {
      recognizer = serviceFactory.recognizer(for: recognizerID)
    }
  }

  /// The recognizer selected for the current and future captures.
  public private(set) var recognizer: any BookRecognizer

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
    statusService: any BookishStatus,
    methodPreference: BookRecognitionMethodPreference = .init()
  ) {
    let factory = BookRecognizerRegistry()
    factory.registerDefaultRecognizers()
    let recognizerID = methodPreference.recognizerID(in: factory)

    self.storage = storage
    self.state = state
    self.statusService = statusService
    self.serviceFactory = factory
    self.methodPreference = methodPreference

    imageData = nil
    candidates = []
    selectedCandidateIDs = []
    error = nil
    isRecognizing = false
    self.recognizerID = recognizerID
    recognizer = serviceFactory.recognizer(for: recognizerID)
  }

  public var recognizerIDs: [String] {
    serviceFactory.recognizerIDs
  }

  public var recognizers: [any BookRecognizer] {
    serviceFactory.recognizers
  }

  /// Whether the supplied recognizer can run on this device.
  public func isRecognizerSupported(_ id: String) -> Bool {
    serviceFactory.recognizerIDs.contains(id)
      && serviceFactory.recognizer(for: id).isSupported
  }

  /// Whether an image has been selected for recognition.
  public var hasImage: Bool {
    imageData != nil
  }

  /// Whether the selected recognizer can run on this device.
  public var isCurrentRecognizerSupported: Bool {
    recognizer.isSupported
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

  /// Selects a supported recognizer without starting recognition.
  public func selectRecognizer(_ id: String) async {
    guard isRecognizerSupported(id) else { return }
    recognizerID = id
    methodPreference.save(recognizerID: id)
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
