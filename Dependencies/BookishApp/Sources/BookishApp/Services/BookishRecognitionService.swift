// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecognition
import Commands
import Foundation
import Observation
import Settings

/// Persists recognised candidates as new book records and refreshes the browser projection.
@MainActor
public final class BookishRecognitionService {
  @MainActor
  public protocol API {
    var candidates: [BookRecognitionCandidate] { get }
    var selectedCandidateIDs: Set<String> { get }
    var canAddBooks: Bool { get }
    var isRecognizing: Bool { get }
    var hasImage: Bool { get }
    var isCurrentRecognitionProviderSupported: Bool { get }
    var selectedRecognitionProviderID: BookRecognitionProviderID { get }
    func selectRecognitionProvider(_ recognitionProviderID: BookRecognitionProviderID)
    func isRecognitionProviderSupported(_ id: BookRecognitionProviderID) -> Bool
    func selectImage(data: Data?)
    func selectAllCandidates()
    func identifyBooks() async
    func addSelectedBooks() async throws
    func deselectAllCandidates()
    func selectCaptureGoodExample()
  }

  @MainActor
  public protocol Provider: CommandCentre {
    var recognitionService: any API { get }
  }

  @MainActor
  @Observable
  public final class State {
    public fileprivate(set) var imageData: Data?
    public fileprivate(set) var candidates: [BookRecognitionCandidate] = []
    public var selectedCandidateIDs: Set<String> = []
    public fileprivate(set) var error: (any Error)?
    public fileprivate(set) var isRecognizing = false
    public fileprivate(set) var recognitionProvider: any BookRecognitionProvider
    public fileprivate(set) var recognitionProviders: [any BookRecognitionProvider]

    fileprivate init(
      recognitionProvider: any BookRecognitionProvider,
      recognitionProviders: [any BookRecognitionProvider]
    ) {
      self.recognitionProvider = recognitionProvider
      self.recognitionProviders = recognitionProviders
    }

    public var selectedRecognitionProviderID: BookRecognitionProviderID {
      recognitionProvider.id
    }
  }

  public let state: State

  /// The storage service used to persist new records.
  private unowned let storage: BookishStorageService

  /// The browser service used to refresh indexes after books are added.
  private let browser: any BookishBrowserService.API

  /// The status service used to report successful additions.
  private let statusService: any BookishStatusService.API

  /// The registry that owns the recognition providers available to the application.
  private let registry: BookRecognitionProviderRegistry

  /// The application settings used to restore and persist the selected recognition provider.
  private let settings: UserDefaults

  public var imageData: Data? { state.imageData }
  public var candidates: [BookRecognitionCandidate] { state.candidates }
  public var selectedCandidateIDs: Set<String> {
    get { state.selectedCandidateIDs }
    set { state.selectedCandidateIDs = newValue }
  }
  public var error: (any Error)? { state.error }
  public var isRecognizing: Bool { state.isRecognizing }
  public var recognitionProvider: any BookRecognitionProvider { state.recognitionProvider }

  /// Creates a record-adder with application-owned services.
  init(
    storage: BookishStorageService,
    browser: any BookishBrowserService.API,
    statusService: any BookishStatusService.API,
    recognitionProviders: [any BookRecognitionProvider],
    settings: UserDefaults
  ) {
    let factory = BookRecognitionProviderRegistry(recognitionProviders: recognitionProviders)
    self.storage = storage
    self.browser = browser
    self.statusService = statusService
    self.registry = factory
    self.settings = settings
    self.state = State(
      recognitionProvider: registry.recognitionProvider(
        for: Self.selectedRecognitionProviderID(in: registry, settings: settings)),
      recognitionProviders: registry.recognitionProviders
    )
  }

  /// The identifier of the recognition provider selected for the current and future captures.
  public var selectedRecognitionProviderID: BookRecognitionProviderID {
    recognitionProvider.id
  }

  /// Selects a recognition provider by its identifier.
  public func selectRecognitionProvider(_ recognitionProviderID: BookRecognitionProviderID) {
    if isRecognitionProviderSupported(recognitionProviderID) {
      state.recognitionProvider = registry.recognitionProvider(for: recognitionProviderID)
      settings.set(recognitionProviderID, forKey: .bookRecognitionProvider)
    }
  }

  /// Replaces application-configured recognition providers and preserves the current choice when possible.
  public func configureRecognitionProviders(_ recognitionProviders: [any BookRecognitionProvider]) {
    let currentIdentifier = recognitionProvider.id
    registry.replaceRecognitionProviders(with: recognitionProviders)
    state.recognitionProvider = Self.resolvedRecognitionProvider(
      in: registry, preferred: currentIdentifier)
    state.recognitionProviders = registry.recognitionProviders
    settings.set(recognitionProvider.id, forKey: .bookRecognitionProvider)
  }

  /// The identifiers of recognition providers registered with the application.
  public var recognitionProviderIDs: [BookRecognitionProviderID] {
    registry.recognitionProviderIDs
  }

  /// The recognition providers registered with the application.
  public var recognitionProviders: [any BookRecognitionProvider] { state.recognitionProviders }

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
    state.imageData = data
    state.candidates = []
    state.selectedCandidateIDs = []
    state.error = nil
  }

  /// Selects the app's bundled image for trying book recognition.
  public func selectCaptureGoodExample() {
    do {
      selectImage(data: try CaptureGoodExample.load())
    } catch {
      selectImage(data: nil)
      state.error = error
    }
  }

  /// Requests identifications for the selected image.
  public func identifyBooks() async {
    guard let imageData else { return }
    state.isRecognizing = true
    state.error = nil
    defer { state.isRecognizing = false }

    do {
      state.candidates = try await recognitionProvider.identifyBooks(in: imageData)
      state.selectedCandidateIDs = []
    } catch {
      state.error = error
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
    // TEMPORARY: refreshes the browser so added books appear; remove when views
    // observe their records and queries.
    try await browser.refresh()
    statusService.report(
      message:
        "Added \(candidates.count) \(candidates.count == 1 ? "book" : "books")"
    )

    let addedIDs = Set(candidates.map(\.id))
    state.candidates.removeAll { addedIDs.contains($0.id) }
    state.selectedCandidateIDs.subtract(addedIDs)
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

extension BookishRecognitionService: BookishRecognitionService.API {}

extension BookishEngine: BookishRecognitionService.Provider {}
