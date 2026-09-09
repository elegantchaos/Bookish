// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Settings
import SwiftUI
import UniformTypeIdentifiers

/// The root view for the Bookish app.
public struct BookishUIStateView: View {
  /// The global UI state that owns browser presentation and sheet state.
  @Bindable private var uiState: BookishUIStateService

  /// The shared navigation route for the browser columns.
  @Environment(BookishNavigationService.self) private var navigation

  /// The command boundary used to report file-panel failures.
  @Environment(\.bookishCommandCentre) private var commander

  /// Whether debug-only browser indexes should be available.
  @AppStorage(.isDeveloperMode) private var isDeveloperMode

  /// Creates the root view over the supplied global UI state.
  public init(uiState: BookishUIStateService) {
    self.uiState = uiState
  }

  /// The SwiftUI content for the datastore app.
  public var body: some View {
    VStack(spacing: 0) {
      NavigationSplitView {
        BrowserIndexListView(navigation: navigation)
      } content: {
        browserContent
      } detail: {
        browserDetail
      }
      .toolbar {
        BookishToolbar(harness: uiState)
      }

      BookishStatusBar(statusService: uiState.statusService, navigation: navigation)
    }
    .fileImporter(
      isPresented: $uiState.isImportingInterchange,
      allowedContentTypes: [.json],
      onCompletion: handleInterchangeImport
    )
    .fileImporter(
      isPresented: $uiState.isImportingDeliciousLibrary,
      allowedContentTypes: [.xml],
      onCompletion: handleDeliciousLibraryImport
    )
    .fileExporter(
      isPresented: $uiState.isExportingInterchange,
      document: uiState.interchangeExportDocument,
      contentType: .json,
      defaultFilename: "Bookish Interchange",
      onCompletion: handleInterchangeExport
    )
    .task(id: isDeveloperMode) {
      await uiState.setShowsDebugIndexes(isDeveloperMode)
    }
  }

  /// The view displayed in the content column for the selected sidebar item.
  @ViewBuilder private var browserContent: some View {
    if let section = navigation.selectedMainSection {
      BookishMainSectionView(section: section)
    } else {
      RecordIndexView(harness: uiState, navigation: navigation)
    }
  }

  /// The view displayed in the detail column for the selected sidebar item.
  @ViewBuilder private var browserDetail: some View {
    if navigation.selectedMainSection == nil {
      RecordDetailView(harness: uiState, navigation: navigation)
    } else {
      ContentUnavailableView("No Selection", systemImage: "list.bullet.rectangle")
    }
  }

  /// Imports a selected interchange file or reports a picker failure.
  private func handleInterchangeImport(_ result: Result<URL, Error>) {
    switch result {
    case .success(let url):
      Task {
        await uiState.importInterchange(from: url)
      }

    case .failure(let error):
      commander?.statusService.report(error: error)
    }
  }

  /// Imports a selected Delicious Library file or reports a picker failure.
  private func handleDeliciousLibraryImport(_ result: Result<URL, Error>) {
    switch result {
    case .success(let url):
      Task {
        await uiState.importDeliciousLibrary(from: url)
      }

    case .failure(let error):
      commander?.statusService.report(error: error)
    }
  }

  /// Reports completion or failure from the interchange export panel.
  private func handleInterchangeExport(_ result: Result<URL, Error>) {
    switch result {
    case .success:
      uiState.didExportInterchange()

    case .failure(let error):
      commander?.statusService.report(error: error)
    }
  }
}

#Preview {
  let engine = BookishEngine()
  BookishUIStateView(uiState: engine.uiState)
    .environment(engine.navigation)
    .environment(\.bookishCommandCentre, engine)
}
