import SwiftUI
import UniformTypeIdentifiers

/// The root view for the datastore app.
public struct BookishHarnessView: View {
  @Bindable private var harness: BookishHarness
  @Environment(BookishNavigationService.self) private var navigation
  private let loadsOnAppear: Bool

  /// Creates the datastore harness view.
  public init(
    harness: BookishHarness = BookishHarness(), loadsOnAppear: Bool = true
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
    .task {
      guard loadsOnAppear else {
        return
      }
      await harness.load()
    }
  }

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
  BookishHarnessView(harness: BookishHarness(navigation: navigation))
    .environment(navigation)
}
