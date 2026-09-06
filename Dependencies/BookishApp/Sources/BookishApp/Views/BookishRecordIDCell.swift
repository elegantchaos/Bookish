// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import BookishRecordView
import SwiftUI

struct BookishRecordIDCell: View {
  let recordID: BookishRecordID
  let harness: BookishHarness

  @State private var record: BookishRecord?
  @State private var layout: BookishRecord?
  @State private var presentationRecords: [BookishRecord] = []

  var body: some View {
    Group {
      if let record {
        BookishRecordCell(
          record: record,
          layout: layout,
          presentationResolver: CascadingPresentationResolver(
            layout: layout,
            presentationRecords: presentationRecords))
      } else {
        Text(recordID.rawValue)
      }
    }
    .task(id: taskID) {
      await load()
    }
  }

  private var taskID: String {
    "\(recordID.rawValue)-\(harness.selectedLayoutID?.rawValue ?? "")-\(harness.revision)"
  }

  private func load() async {
    do {
      record = try await harness.record(id: recordID)
      layout = try await harness.selectedLayout()
      if let record {
        presentationRecords = try await harness.presentations(for: record.kind, layout: layout)
      }
    } catch {
      harness.report(error: error)
    }
  }
}
