import SwiftUI

/// Hosts source selection, proposal review, and completed results in the Import workflow.
struct BookishImportWorkflowView: View {
  @Environment(BookishCommander.self) private var commander
  @Environment(BookishImportingService.State.self) private var importing

  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        commander.button(ImportInterchangeCommand()) {
          Label("Interchange File…", systemImage: "square.and.arrow.down")
        }
        commander.button(ImportOtherDeliciousLibraryCommand()) {
          Label("Delicious Library File…", systemImage: "books.vertical")
        }
        #if os(macOS)
          commander.button(ImportKindleLibraryCommand()) {
            Label("Kindle Library…", systemImage: "books.vertical")
          }
        #endif
      }
      .disabled(
        importing.pendingImportPlan != nil || importing.isPreparingImport
          || importing.isApplyingImport
      )
      .padding()

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
          description: Text("Choose an import source above or from the Import menu."))
      }
    }
    .navigationTitle("Import")
    .toolbar {
      if importing.pendingImportPlan == nil {
        commander.toolbarItem(ImportInterchangeCommand())
        commander.toolbarItem(ImportOtherDeliciousLibraryCommand())
      } else {
        commander.toolbarItem(CancelPendingImportCommand())
        commander.toolbarItem(ApplyPendingImportCommand())
      }
    }
  }
}
