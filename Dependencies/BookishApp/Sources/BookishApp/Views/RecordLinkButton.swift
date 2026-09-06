// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import BookishRecordView
import SwiftUI

struct RecordLinkButton: View {
  let recordID: BookishRecordID
  let harness: BookishHarness
  let navigation: BookishNavigationService

  @State private var presentation: BookishRecordLinkPresentation?

  var body: some View {
    Button(action: navigate) {
      HStack(spacing: 6) {
        BookishRecordThumbnail(
          url: presentation?.imageURL,
          placeholderSystemImage: presentation?.placeholderSystemImage ?? "doc")
        Text(presentation?.name ?? recordID.rawValue)
      }
    }
    .task(id: taskID) {
      await loadPresentation()
    }
    #if os(macOS)
      .buttonStyle(.link)
    #endif
  }

  private func navigate() {
    navigation.performWithoutWaiting(NavigateToRecordCommand(recordID: recordID))
  }

  private var taskID: String {
    "\(recordID.rawValue)-\(harness.revision)"
  }

  private func loadPresentation() async {
    do {
      guard let record = try await harness.record(id: recordID) else {
        presentation = nil
        return
      }

      presentation = BookishRecordLinkPresentation(
        record: record,
        placeholderSystemImage: try await harness.recordKindMetadata(for: record.kind)?
          .string(BookishRecordKey.icon) ?? "doc")
    } catch {
      harness.report(error: error)
    }
  }
}
