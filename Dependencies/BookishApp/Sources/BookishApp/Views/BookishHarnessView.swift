// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Settings
import SwiftUI
import UniformTypeIdentifiers

/// The root view for the datastore app.
public struct BookishHarnessView: View {
  /// The datastore coordinator that owns the browser state.
  @Bindable private var harness: BookishHarness

  /// The shared navigation route for the browser columns.
  @Environment(BookishNavigationService.self) private var navigation

  /// Whether debug-only browser indexes should be available.
  @AppStorage(.isDeveloperMode) private var isDeveloperMode

  /// Whether the view initiates the initial datastore load.
  private let loadsOnAppear: Bool

  /// Creates the datastore harness view.
  public init(
    harness: BookishHarness = BookishHarness(),
    loadsOnAppear: Bool = true
  ) {
    self.harness = harness
    self.loadsOnAppear = loadsOnAppear
  }

  /// The SwiftUI content for the datastore app.
  public var body: some View {
    VStack(spacing: 0) {
      NavigationSplitView {
        BrowserIndexListView(harness: harness, navigation: navigation)
      } content: {
        RecordIndexView(harness: harness, navigation: navigation)
      } detail: {
        RecordDetailView(harness: harness, navigation: navigation)
      }
      .toolbar {
        BookishToolbar(harness: harness)
      }

      BookishStatusBar(harness: harness)
    }
    .fileImporter(
      isPresented: $harness.isImportingInterchange,
      allowedContentTypes: [.json],
      onCompletion: handleInterchangeImport
    )
    .fileImporter(
      isPresented: $harness.isImportingDeliciousLibrary,
      allowedContentTypes: [.xml],
      onCompletion: handleDeliciousLibraryImport
    )
    .fileExporter(
      isPresented: $harness.isExportingInterchange,
      document: harness.interchangeExportDocument,
      contentType: .json,
      defaultFilename: "Bookish Interchange",
      onCompletion: handleInterchangeExport
    )
    .task(id: isDeveloperMode) {
      await harness.setShowsDebugIndexes(isDeveloperMode)
      await loadIfNeeded()
    }
  }

  /// Starts the initial datastore load when this view owns startup.
  private func loadIfNeeded() async {
    guard loadsOnAppear else {
      return
    }

    await harness.load()
  }

  /// Imports a selected interchange file or reports a picker failure.
  private func handleInterchangeImport(_ result: Result<URL, Error>) {
    switch result {
    case .success(let url):
      Task {
        await harness.importInterchange(from: url)
      }

    case .failure(let error):
      harness.report(error: error)
    }
  }

  /// Imports a selected Delicious Library file or reports a picker failure.
  private func handleDeliciousLibraryImport(_ result: Result<URL, Error>) {
    switch result {
    case .success(let url):
      Task {
        await harness.importDeliciousLibrary(from: url)
      }

    case .failure(let error):
      harness.report(error: error)
    }
  }

  /// Reports completion or failure from the interchange export panel.
  private func handleInterchangeExport(_ result: Result<URL, Error>) {
    switch result {
    case .success:
      harness.didExportInterchange()

    case .failure(let error):
      harness.report(error: error)
    }
  }
}

#Preview {
  let navigation = BookishNavigationService()
  let harness = BookishHarness(navigation: navigation)
  BookishHarnessView(harness: harness)
    .environment(navigation)
    .environment(\.bookishCommandCentre, BookishCommandCentre(harness: harness))
}
