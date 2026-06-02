import BookishDatastore
import BookishRecord
import BookishRecordView
import SwiftUI

/// The root view for the datastore prototype app.
public struct DatastorePrototypeHarnessView: View {
  @State private var harness = DatastorePrototypeHarness()

  /// Creates the prototype harness view.
  public init() {}

  /// The SwiftUI content for the prototype app.
  public var body: some View {
    NavigationSplitView {
      RecordIndexView(harness: harness)
    } detail: {
      RecordDetailView(harness: harness)
    }
    .toolbar {
      PrototypeToolbar(harness: harness)
    }
    .safeAreaInset(edge: .bottom) {
      PrototypeStatusBar(harness: harness)
    }
    .task {
      await harness.load()
    }
  }
}

private struct RecordIndexView: View {
  @Bindable var harness: DatastorePrototypeHarness

  var body: some View {
    List(selection: $harness.selection) {
      Section("Records") {
        ForEach(harness.records) { record in
          PrototypeRecordCell(record: record, layout: harness.selectedLayout)
            .tag(PrototypeBrowserSelection.record(record.id))
        }
      }

      Section("Mutations") {
        ForEach(harness.mutations) { mutation in
          PrototypeMutationCell(mutation: mutation)
            .tag(PrototypeBrowserSelection.mutation(mutation.id))
        }
      }
    }
    .navigationTitle("Datastore")
  }
}

private struct RecordDetailView: View {
  @Bindable var harness: DatastorePrototypeHarness

  var body: some View {
    Group {
      if let record = harness.selectedRecord {
        PrototypeRecordView(record: record, layout: harness.selectedLayout)
      } else if let mutation = harness.selectedMutation {
        PrototypeMutationView(mutation: mutation)
      } else {
        ContentUnavailableView(
          "No Selection", systemImage: "list.bullet.rectangle", description: Text(harness.status))
      }
    }
  }
}

private struct PrototypeToolbar: ToolbarContent {
  @Bindable var harness: DatastorePrototypeHarness

  var body: some ToolbarContent {
    ToolbarItem {
      Picker("Layout", selection: $harness.selectedLayoutID) {
        Text("Default").tag(Optional<BookishRecordID>.none)
        ForEach(harness.layouts) { layout in
          Text(layout.string("title") ?? layout.id.rawValue)
            .tag(Optional(layout.id))
        }
      }
      .pickerStyle(.menu)
    }

    ToolbarItemGroup {
      Button(action: markReading) {
        Label("Reading", systemImage: "book")
      }
      .disabled(harness.selectedRecord == nil)

      Button(action: markFinished) {
        Label("Finished", systemImage: "checkmark.circle")
      }
      .disabled(harness.selectedRecord == nil)

      Button(action: simulateRemoteUpdate) {
        Label("Remote", systemImage: "icloud.and.arrow.down")
      }
      .disabled(harness.selectedRecord == nil)
    }
  }

  private func markReading() {
    Task { await harness.markReading() }
  }

  private func markFinished() {
    Task { await harness.markFinished() }
  }

  private func simulateRemoteUpdate() {
    Task { await harness.simulateRemoteUpdate() }
  }
}

private struct PrototypeStatusBar: View {
  let harness: DatastorePrototypeHarness

  var body: some View {
    HStack {
      Text(harness.status)
      Spacer()
      Text("\(harness.records.count) records")
      Text("\(harness.mutations.count) mutations")
    }
    .font(.caption)
    .foregroundStyle(.secondary)
    .padding()
    .background(.bar)
  }
}

#Preview {
  DatastorePrototypeHarnessView()
}
