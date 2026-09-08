// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import SwiftUI

/// Resolves a linked layout item and renders its supported configuration kind.
struct RecordLayoutItemView: View {
  /// The linked configuration record identifier from the host layout.
  let linkedLayoutID: BookishRecordID

  /// The record whose fields or relationships are being displayed.
  let host: BookishRecord

  /// The datastore coordinator used to resolve the linked configuration.
  let harness: BookishUIStateService

  /// The command boundary used to report configuration failures.
  @Environment(\.bookishCommandCentre) private var commander

  /// The navigation service used by record links in nested layouts.
  let navigation: BookishNavigationService

  /// The ancestor layout identifiers, used to prevent recursive sections.
  let layoutPath: Set<BookishRecordID>

  /// The resolved linked configuration record.
  @State private var configuration: BookishRecord?

  /// A diagnostic description of a configuration failure.
  @State private var errorDescription: String?

  /// Whether the linked configuration is still being resolved.
  @State private var isLoading = true

  @AppStorage(.isDeveloperMode) var isDeveloperMode

  /// Creates a linked layout item outside any nested layout section.
  init(
    linkedLayoutID: BookishRecordID,
    host: BookishRecord,
    harness: BookishUIStateService,
    navigation: BookishNavigationService
  ) {
    self.init(
      linkedLayoutID: linkedLayoutID,
      host: host,
      harness: harness,
      navigation: navigation,
      layoutPath: []
    )
  }

  /// Creates a linked layout item with the current nested-layout ancestry.
  init(
    linkedLayoutID: BookishRecordID,
    host: BookishRecord,
    harness: BookishUIStateService,
    navigation: BookishNavigationService,
    layoutPath: Set<BookishRecordID>
  ) {
    self.linkedLayoutID = linkedLayoutID
    self.host = host
    self.harness = harness
    self.navigation = navigation
    self.layoutPath = layoutPath
  }

  /// The resolved section, a brief loading indicator, or DEBUG-only diagnostics.
  var body: some View {
    Group {
      if let configuration {
        switch configuration.kind {
        case BookishRecordKind.layout:
          RecordLayoutSectionView(
            layout: configuration,
            host: host,
            harness: harness,
            navigation: navigation,
            layoutPath: layoutPath
          )
        case BookishRecordKind.querySection:
          RecordQuerySectionView(
            sectionID: linkedLayoutID,
            host: host,
            harness: harness
          )
        default:
          EmptyView()
        }
      } else if isLoading {
        ProgressView()
          .controlSize(.small)
      }

      if isDeveloperMode {
        diagnostics
      }
    }
    .task(id: taskID) {
      await load()
    }
  }

  /// Identifies a linked configuration lookup for a particular host and datastore revision.
  private var taskID: String {
    "\(linkedLayoutID.rawValue)-\(host.id.rawValue)-\(harness.revision)"
  }

  /// Resolves and validates the linked configuration record.
  private func load() async {
    errorDescription = nil
    isLoading = true
    defer { isLoading = false }

    do {
      guard let configuration = try await harness.storageService.record(id: linkedLayoutID)
      else {
        self.configuration = nil
        errorDescription = "The linked layout item is missing."
        return
      }

      guard
        configuration.kind == BookishRecordKind.layout
          || configuration.kind == BookishRecordKind.querySection
      else {
        self.configuration = nil
        errorDescription = "The linked record is not a layout or query section."
        return
      }

      guard
        configuration.kind != BookishRecordKind.layout
          || !layoutPath.contains(configuration.id)
      else {
        self.configuration = nil
        errorDescription = "The linked layout would create a recursive section."
        return
      }

      self.configuration = configuration
    } catch {
      configuration = nil
      errorDescription = error.localizedDescription
      commander?.statusService.report(error: error)
    }
  }

  #if DEBUG
    /// Shows linked-layout configuration failures while developing the interface.
    @ViewBuilder
    private var diagnostics: some View {
      if let errorDescription {
        Text(errorDescription)
          .font(.caption)
          .foregroundStyle(.red)
      }
    }
  #else
    /// Omits linked-layout diagnostics from release builds.
    private var diagnostics: EmptyView {
      EmptyView()
    }
  #endif
}
