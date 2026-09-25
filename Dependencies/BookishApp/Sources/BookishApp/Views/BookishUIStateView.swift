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
  @Environment(BookishUIStateService.self) private var uiState

  /// The command boundary used to report file-panel failures.
  @Environment(BookishCommander.self) private var commander

  /// Reports file-picker failures from the root view.
  @Environment(BookishStatusService.State.self) private var status

  /// The navigation state that selects the visible workflow or browser.
  @Environment(BookishNavigationService.State.self) private var navigation

  /// Whether debug-only browser indexes should be available.
  @AppStorage(.isDeveloperMode) private var isDeveloperMode

  /// The SwiftUI content for the datastore app.
  public var body: some View {
    @Bindable var uiState = uiState
    VStack(spacing: 0) {
      if let section = navigation.selectedMainSection {
        WorkflowNavigationSplitView(section: section)
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
      commander.perform(SetDebugIndexVisibilityCommand(isVisible: isDeveloperMode))
    }
    #if os(iOS)
      .sheet(isPresented: $uiState.isShowingSettings) {
        NavigationStack {
          BookishSettingsView()
          .toolbar {
            commander.toolbarItem(CloseSettingsCommand(), placement: .topBarTrailing)
          }
        }
      }
    #endif
  }

}

/// Displays the library browser with independent sidebar, index, and detail columns.
private struct BrowserNavigationSplitView: View {
  /// The library browser columns.
  var body: some View {
    NavigationSplitView {
      BrowserIndexListView()
        .toolbar {
          #if os(iOS)
            BookishSettingsToolbar(isSidebar: true)
          #endif
        }
    } content: {
      RecordIndexView()
        .toolbar {
          #if os(iOS)
            BookishSettingsToolbar()
          #endif
        }
    } detail: {
      RecordDetailView()
        .toolbar {
          #if os(iOS)
            BookishSettingsToolbar()
          #endif
        }
    }
  }
}

/// Displays a workflow alongside the shared sidebar.
private struct WorkflowNavigationSplitView: View {
  /// The selected workflow displayed in the detail area.
  let section: BookishMainSection

  /// The sidebar and full-width workflow content.
  var body: some View {
    NavigationSplitView {
      BrowserIndexListView()
        .toolbar {
          #if os(iOS)
            BookishSettingsToolbar(isSidebar: true)
          #endif
        }
    } detail: {
      BookishMainSectionView(section: section)
        .toolbar {
          #if os(iOS)
            BookishSettingsToolbar()
          #endif
        }
    }
  }
}

extension BookishUIStateView {
  /// Imports a selected interchange file or reports a picker failure.
  private func handleInterchangeImport(_ result: Result<URL, Error>) {
    switch result {
    case .success(let url):
      commander.perform(ImportSelectedInterchangeCommand(url: url))

    case .failure(let error):
      status.report(error: error)
    }
  }

  /// Imports a selected Delicious Library file or reports a picker failure.
  private func handleDeliciousLibraryImport(_ result: Result<URL, Error>) {
    switch result {
    case .success(let url):
      commander.perform(ImportSelectedDeliciousLibraryCommand(url: url))

    case .failure(let error):
      status.report(error: error)
    }
  }

  /// Reports completion or failure from the interchange export panel.
  private func handleInterchangeExport(_ result: Result<URL, Error>) {
    switch result {
    case .success:
      uiState.didExportInterchange()

    case .failure(let error):
      status.report(error: error)
    }
  }
}

#Preview {
  let engine = BookishEngine()
  BookishUIStateView()
    .modifier(BookishEnvironmentInjector(engine: engine))
}
