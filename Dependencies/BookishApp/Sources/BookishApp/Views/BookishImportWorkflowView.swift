import SwiftUI

/// Hosts source selection, proposal review, and completed results in the Import workflow.
struct BookishImportWorkflowView: View {
  @Environment(BookishCommander.self) private var commander
  @Environment(BookishUIStateService.self) private var uiState

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
        uiState.pendingImportPlan != nil || uiState.isPreparingImport || uiState.isApplyingImport
      )
      .padding()

      if let error = uiState.importErrorMessage, uiState.pendingImportPlan != nil {
        Label(error, systemImage: "exclamationmark.triangle")
          .foregroundStyle(.red)
          .padding(.horizontal)
      }

      if uiState.isPreparingImport || uiState.isApplyingImport {
        ProgressView(uiState.isPreparingImport ? "Reading import source" : "Applying import")
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let plan = uiState.pendingImportPlan {
        BookishImportReviewView(plan: plan)
      } else if let result = uiState.lastImportResult {
        BookishImportResultView(result: result)
      } else if let error = uiState.importErrorMessage {
        ContentUnavailableView(
          "Import Failed", systemImage: "exclamationmark.triangle", description: Text(error))
      } else {
        ContentUnavailableView(
          "No Import Selected", systemImage: "square.and.arrow.down",
          description: Text("Choose an import source above or from the Import menu."))
      }
    }
    .navigationTitle("Import")
  }
}
