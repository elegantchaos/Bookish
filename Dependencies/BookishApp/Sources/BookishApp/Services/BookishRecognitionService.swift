// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecognition
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
  private let statusService: any BookishStatusService.API

  /// The registry that owns the recognition providers available to the application.
  private let registry: BookRecognitionProviderRegistry

  /// The application settings used to restore and persist the selected recognition provider.
  private let settings: UserDefaults

  /// The data selected by the user for recognition.
  public private(set) var imageData: Data?

  /// Candidate books returned by the recognition provider.
  public private(set) var candidates: [BookRecognitionCandidate]

  /// The candidate identifiers selected for addition.
  public var selectedCandidateIDs: Set<String>

  /// A recognition error suitable for display.
  public private(set) var error: (any Error)?

  /// Whether a request is currently underway.
  public private(set) var isRecognizing: Bool

  /// The recognition provider selected for the current and future captures.
  public private(set) var recognitionProvider: any BookRecognitionProvider

  /// Creates a record-adder with application-owned services.
  init(
    storage: BookishStorageService,
    state: BookishUIStateService,
    statusService: any BookishStatusService.API,
    recognitionProviders: [any BookRecognitionProvider],
    settings: UserDefaults
  ) {
    let factory = BookRecognitionProviderRegistry(recognitionProviders: recognitionProviders)
    self.storage = storage
    self.state = state
    self.statusService = statusService
    self.registry = factory
    self.settings = settings
    imageData = nil
    candidates = []
    selectedCandidateIDs = []
    error = nil
    isRecognizing = false
    recognitionProvider = registry.recognitionProvider(
      for: Self.selectedRecognitionProviderID(in: registry, settings: settings)
    )
  }

  /// The identifier of the recognition provider selected for the current and future captures.
  public var selectedRecognitionProviderID: BookRecognitionProviderID {
    recognitionProvider.id
  }

  /// Selects a recognition provider by its identifier.
  public func selectRecognitionProvider(_ recognitionProviderID: BookRecognitionProviderID) {
    if isRecognitionProviderSupported(recognitionProviderID) {
      recognitionProvider = registry.recognitionProvider(for: recognitionProviderID)
      settings.set(recognitionProviderID, forKey: .bookRecognitionProvider)
    }
  }

  /// Replaces application-configured recognition providers and preserves the current choice when possible.
  public func configureRecognitionProviders(_ recognitionProviders: [any BookRecognitionProvider]) {
    let currentIdentifier = recognitionProvider.id
    registry.replaceRecognitionProviders(with: recognitionProviders)
    recognitionProvider = Self.resolvedRecognitionProvider(
      in: registry, preferred: currentIdentifier)
    settings.set(recognitionProvider.id, forKey: .bookRecognitionProvider)
  }

  /// The identifiers of recognition providers registered with the application.
  public var recognitionProviderIDs: [BookRecognitionProviderID] {
    registry.recognitionProviderIDs
  }

  /// The recognition providers registered with the application.
  public var recognitionProviders: [any BookRecognitionProvider] { registry.recognitionProviders }

  /// Whether the supplied recognition provider can run on this device.
  public func isRecognitionProviderSupported(_ id: BookRecognitionProviderID) -> Bool {
    registry.recognitionProviderIDs.contains(id)
      && registry.recognitionProvider(for: id).isSupported
  }

  /// Whether an image has been selected for recognition.
  public var hasImage: Bool {
    imageData != nil
  }

  /// Whether the selected recognition provider can run on this device.
  public var isCurrentRecognitionProviderSupported: Bool {
    recognitionProvider.isSupported
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
      candidates = try await recognitionProvider.identifyBooks(in: imageData)
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
    guard !candidates.isEmpty else { return }
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

  /// Selects a supported preferred recognition provider or the first supported fallback.
  private static func resolvedRecognitionProvider(
    in registry: BookRecognitionProviderRegistry,
    preferred: BookRecognitionProviderID
  ) -> any BookRecognitionProvider {
    if registry.recognitionProviderIDs.contains(preferred),
      registry.recognitionProvider(for: preferred).isSupported
    {
      return registry.recognitionProvider(for: preferred)
    }
    guard
      let fallback = registry.recognitionProviderIDs.first(where: {
        registry.recognitionProvider(for: $0).isSupported
      })
    else {
      fatalError("Bookish requires at least one supported book recognition provider.")
    }
    return registry.recognitionProvider(for: fallback)
  }

  /// Returns the saved recognition provider when it is registered and supported, or a fallback.
  static func selectedRecognitionProviderID(
    in registry: BookRecognitionProviderRegistry,
    settings: UserDefaults
  ) -> BookRecognitionProviderID {
    let preferred = settings.value(forKey: .bookRecognitionProvider)
    return resolvedRecognitionProvider(in: registry, preferred: preferred).id
  }
}
