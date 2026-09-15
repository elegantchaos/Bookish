// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCapture
import Foundation
import Observation
import Settings

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

  /// The registry that owns the recognizers available to the application.
  private let serviceFactory: BookRecognizerRegistry

  /// The application settings store that remembers the selected recognizer.
  private let settings: UserDefaults

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
    settings: UserDefaults = .standard
  ) {
    let factory = BookRecognizerRegistry()
    factory.registerDefaultRecognizers()
    let recognizerID = Self.selectedRecognizerID(in: factory, settings: settings)

    self.storage = storage
    self.state = state
    self.statusService = statusService
    self.serviceFactory = factory
    self.settings = settings

    imageData = nil
    candidates = []
    selectedCandidateIDs = []
    error = nil
    isRecognizing = false
    self.recognizerID = recognizerID
    recognizer = serviceFactory.recognizer(for: recognizerID)
  }

  /// The identifiers of recognizers registered with the application.
  public var recognizerIDs: [String] {
    serviceFactory.recognizerIDs
  }

  /// The recognizers registered with the application.
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
    settings.set(id, forKey: .bookRecognitionProvider)
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

  /// Returns the saved recognizer when available, otherwise the first available recognizer.
  static func selectedRecognizerID(
    in registry: BookRecognizerRegistry,
    settings: UserDefaults
  ) -> String {
    let storedID = settings.value(forKey: .bookRecognitionProvider)
    if registry.recognizerIDs.contains(storedID), registry.recognizer(for: storedID).isSupported {
      return storedID
    }

    guard
      let fallbackID = registry.recognizerIDs.first(where: {
        registry.recognizer(for: $0).isSupported
      })
    else {
      fatalError("Book recognition requires at least one available method.")
    }
    return fallbackID
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
