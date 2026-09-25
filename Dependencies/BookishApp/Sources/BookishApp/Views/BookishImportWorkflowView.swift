import Settings
import SwiftUI

/// Hosts source selection, proposal review, and completed results in the Import workflow.
struct BookishImportWorkflowView: View {
  @Environment(BookishCommander.self) private var commander
  @Environment(BookishImportingService.State.self) private var importing
  @AppStorage(.featureMode) private var featureMode

  var body: some View {
    VStack(alignment: .leading) {
      if let error = importing.importErrorMessage, importing.pendingImportPlan != nil {
        Label(error, systemImage: "exclamationmark.triangle")
          .foregroundStyle(.red)
          .padding(.horizontal)
      }

      if importing.isPreparingImport || importing.isApplyingImport {
        ProgressView(importing.isPreparingImport ? "Reading import source" : "Applying import")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let plan = importing.pendingImportPlan {
        BookishImportReviewView(plan: plan)
      } else if let result = importing.lastImportResult {
        BookishImportResultView(result: result)
      } else if let error = importing.importErrorMessage {
        ContentUnavailableView(
          "Import Failed", systemImage: "exclamationmark.triangle", description: Text(error))
      } else {
        ContentUnavailableView(
          "No Import Selected", systemImage: "square.and.arrow.down",
          description: emptyImportDescription)
      }
    }
    .navigationTitle("Import")
    .toolbar {
      if importing.pendingImportPlan != nil {
        commander.toolbarItem(CancelPendingImportCommand())
        commander.toolbarItem(ApplyPendingImportCommand())
      } else if !importing.isPreparingImport && !importing.isApplyingImport {
        commander.toolbarItem(ImportInterchangeCommand())
        ToolbarItem {
          Menu {
            if featureMode.showsAdvanced {
              commander.button(ImportDeliciousLibrarySampleCommand(sample: .small))
              commander.button(ImportDeliciousLibrarySampleCommand(sample: .full))
              Divider()
            }
            commander.button(ImportOtherDeliciousLibraryCommand())
          } label: {
            Label("Delicious Library…", systemImage: "books.vertical")
          }
        }
        ToolbarItem {
          Menu {
            commander.button(ImportKindleLibrarySampleCommand())
            commander.button(ImportKindleLibraryCommand())
          } label: {
            Label("Kindle Library…", systemImage: "book.closed")
          }
        }
      }
    }
  }

  /// The empty-state guidance for platforms with and without an Import menu.
  private var emptyImportDescription: Text {
    #if os(iOS)
      Text("Choose an import source from the toolbar.")
    #else
      Text("Choose an import source from the toolbar or Import menu.")
    #endif
  }
}
