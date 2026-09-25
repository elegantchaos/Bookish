// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 25/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands

/// Owns browser index visibility and refreshes browser-facing state after records change.
@MainActor
public final class BookishBrowserService {
  /// Whether debug-only indexes are included when the app starts.
  public let defaultShowsDebugIndexes: Bool

  /// Whether debug-only indexes are currently included in the browser.
  public private(set) var showsDebugIndexes: Bool

  /// The navigation service whose indexes and selection are refreshed.
  private let navigation: BookishNavigationService

  /// The presentation service whose layouts are refreshed.
  private let presentation: BookishPresentationService

  /// The storage service whose record revision is advanced after a refresh.
  private let storage: BookishStorageService

  /// The status service used to report refresh failures.
  private let statusService: any BookishStatusService.API

  /// Creates a browser service and keeps layouts in step with index selection.
  public init(
    navigation: BookishNavigationService,
    presentation: BookishPresentationService,
    storage: BookishStorageService,
    statusService: any BookishStatusService.API,
    defaultShowsDebugIndexes: Bool = false
  ) {
    self.navigation = navigation
    self.presentation = presentation
    self.storage = storage
    self.statusService = statusService
    self.defaultShowsDebugIndexes = defaultShowsDebugIndexes
    self.showsDebugIndexes = defaultShowsDebugIndexes
    navigation.setRecordIndexSelectionHandler { [weak presentation, weak navigation] in
      try await presentation?.refresh(for: navigation?.selectedRecordIndex)
    }
  }
}

extension BookishBrowserService {
  /// Changes browser settings and refreshes browser state.
  @MainActor
  public protocol API: AnyObject {
    /// Updates whether debug-only indexes are visible.
    func setShowsDebugIndexes(_ isVisible: Bool) async

    /// Refreshes browser indexes, layouts, and views that display stored records.
    ///
    /// TEMPORARY: services call this after writing records because views do not yet
    /// observe the records and queries they display. Remove these calls when record
    /// observation is refactored; see
    /// `Extras/Journal/2026-09-25-fine-grained-record-observation.md`.
    func refresh() async throws
  }

  @MainActor
  public protocol Access: CommandCentre {
    var browserAPI: any API { get }
  }
}

extension BookishBrowserService: BookishBrowserService.API {
  public func setShowsDebugIndexes(_ showsDebugIndexes: Bool) async {
    guard self.showsDebugIndexes != showsDebugIndexes else {
      return
    }

    self.showsDebugIndexes = showsDebugIndexes

    do {
      try await refresh()
    } catch {
      statusService.report(error: error)
    }
  }

  public func refresh() async throws {
    try await navigation.refreshRecordIndexes(showsDebugIndexes: showsDebugIndexes)
    try await presentation.refresh(for: navigation.selectedRecordIndex)
    // TEMPORARY: a coarse signal that makes every visible record view reload.
    // Remove when views observe their own records and queries.
    storage.didRefreshRecords()
  }
}

extension BookishEngine: BookishBrowserService.Access {}
