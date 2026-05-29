import BookishDatastore
import BookishRecordView
import SwiftUI

@main
struct DatastorePrototypeApplication: App {
  var body: some Scene {
    WindowGroup {
      DatastorePrototypeHarnessView()
    }
  }
}

@MainActor
@Observable
private final class DatastorePrototypeHarness {
  private(set) var record: StoredRecord?
  private(set) var layout: StoredRecord?
  private(set) var mutationCount = 0
  private(set) var status = "Loading"

  private let bookID = RecordID("prototype-book")
  private let layoutID = RecordID("prototype-book-layout")
  private var prototype: DatastorePrototype?

  func load() async {
    do {
      let directory = try datastoreDirectory()
      let prototype = try await DatastorePrototype(directoryURL: directory)
      self.prototype = prototype

      try await seedIfNeeded(using: prototype)
      try await refresh()
      status = "Ready"
    } catch {
      status = error.localizedDescription
    }
  }

  func markReading() async {
    await setStatus("Reading")
  }

  func markFinished() async {
    await setStatus("Finished")
  }

  func simulateRemoteUpdate() async {
    guard let prototype else {
      return
    }

    do {
      let mutation = MutationRecord(
        operation: .setProperty(
          recordID: bookID,
          kind: "book",
          key: "note",
          value: .string(
            "Remote mutation arrived at \(Date().formatted(date: .omitted, time: .shortened))")
        )
      )
      try await prototype.mutationService.receiveRemoteMutation(mutation)
      try await refresh()
      status = "Applied remote mutation"
    } catch {
      status = error.localizedDescription
    }
  }

  private func setStatus(_ value: String) async {
    guard let prototype else {
      return
    }

    do {
      try await prototype.mutationService.perform(
        .setProperty(recordID: bookID, kind: "book", key: "status", value: .string(value))
      )
      try await refresh()
      status = "Set status to \(value)"
    } catch {
      status = error.localizedDescription
    }
  }

  private func refresh() async throws {
    guard let prototype else {
      return
    }

    record = try await prototype.recordService.record(id: bookID)
    layout = try await prototype.recordService.record(id: layoutID)
    mutationCount = try await prototype.mutationStore.mutations().count
  }

  private func seedIfNeeded(using prototype: DatastorePrototype) async throws {
    if try await prototype.recordService.record(id: bookID) == nil {
      try await prototype.mutationService.perform(
        .upsertRecord(
          StoredRecord(
            id: bookID,
            kind: "book",
            properties: [
              "title": .string("The Left Hand of Darkness"),
              "author": .string("Ursula K. Le Guin"),
              "status": .string("To Read"),
              "note": .string("Seeded by the prototype harness"),
            ]
          )
        )
      )
    }

    if try await prototype.recordService.record(id: layoutID) == nil {
      try await prototype.mutationService.perform(
        .upsertRecord(
          StoredRecord(
            id: layoutID,
            kind: "layout",
            properties: [
              "title": .string("Prototype Book"),
              "fields": .list([
                .string("title"), .string("author"), .string("status"), .string("note"),
              ]),
            ]
          )
        )
      )
    }
  }

  private func datastoreDirectory() throws -> URL {
    let applicationSupport = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true
    )
    let directory = applicationSupport.appending(
      path: "BookishDatastorePrototype", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    return directory
  }
}

private struct DatastorePrototypeHarnessView: View {
  @State private var harness = DatastorePrototypeHarness()

  var body: some View {
    NavigationStack {
      Group {
        if let record = harness.record, let layout = harness.layout {
          PrototypeRecordView(record: record, layout: layout)
        } else {
          ContentUnavailableView(
            "No Record", systemImage: "book", description: Text(harness.status))
        }
      }
      .toolbar {
        ToolbarItemGroup {
          Button {
            Task { await harness.markReading() }
          } label: {
            Label("Reading", systemImage: "book")
          }

          Button {
            Task { await harness.markFinished() }
          } label: {
            Label("Finished", systemImage: "checkmark.circle")
          }

          Button {
            Task { await harness.simulateRemoteUpdate() }
          } label: {
            Label("Remote", systemImage: "icloud.and.arrow.down")
          }
        }
      }
      .safeAreaInset(edge: .bottom) {
        HStack {
          Text(harness.status)
          Spacer()
          Text("\(harness.mutationCount) mutations")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding()
        .background(.bar)
      }
    }
    .task {
      await harness.load()
    }
  }
}

#Preview {
  DatastorePrototypeHarnessView()
}
