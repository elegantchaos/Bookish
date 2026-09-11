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

  /// The command boundary used to report file-panel failures.
  @Environment(BookishEngine.self) private var commander

  /// Whether debug-only browser indexes should be available.
  @AppStorage(.isDeveloperMode) private var isDeveloperMode

  /// Creates the root view over the supplied global UI state.
  public init(uiState: BookishUIStateService) {
    self.uiState = uiState
  }

  /// The SwiftUI content for the datastore app.
  public var body: some View {
    VStack(spacing: 0) {
      if let section = commander.navigationService.selectedMainSection {
        WorkflowNavigationSplitView(section: section, uiState: uiState)
      } else {
        BrowserNavigationSplitView()
      }

      BookishStatusBar()
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

}

/// Displays the library browser with independent sidebar, index, and detail columns.
private struct BrowserNavigationSplitView: View {
  @Environment(BookishEngine.self) var commander
  
  /// The global UI state that owns browser presentation and sheet state.
  var uiState: BookishUIStateService { commander.uiState }

  /// The shared navigation route for the browser columns.
  var navigation: BookishNavigationService { commander.navigation }

  /// The library browser columns.
  var body: some View {
    NavigationSplitView {
      BrowserIndexListView()
    } content: {
      RecordIndexView()
    } detail: {
      RecordDetailView()
    }
    .toolbar {
      BookishToolbar(harness: uiState)
    }
  }
}

/// Displays a workflow alongside the shared sidebar.
private struct WorkflowNavigationSplitView: View {
  /// The selected workflow displayed in the detail area.
  let section: BookishMainSection

  /// The global UI state that owns browser presentation and sheet state.
  let uiState: BookishUIStateService

  /// The sidebar and full-width workflow content.
  var body: some View {
    NavigationSplitView {
      BrowserIndexListView()
    } detail: {
      BookishMainSectionView(section: section)
    }
    .toolbar {
      BookishToolbar(harness: uiState)
    }
  }
}

extension BookishUIStateView {
  /// Imports a selected interchange file or reports a picker failure.
  private func handleInterchangeImport(_ result: Result<URL, Error>) {
    switch result {
    case .success(let url):
      Task {
        await uiState.importInterchange(from: url)
      }

    case .failure(let error):
      commander.statusService.report(error: error)
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
      commander.statusService.report(error: error)
    }
  }

  /// Reports completion or failure from the interchange export panel.
  private func handleInterchangeExport(_ result: Result<URL, Error>) {
    switch result {
    case .success:
      uiState.didExportInterchange()

    case .failure(let error):
      commander.statusService.report(error: error)
    }
  }
}

#Preview {
  let engine = BookishEngine()
  BookishUIStateView(uiState: engine.uiState)
    .environment(engine.navigation)
    .environment(engine)
}
