// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import BookishRecordView
import SwiftUI

/// Displays a linked record using its resolved name, image, and kind icon.
struct RecordLinkButton: View {
  /// The identifier of the linked record.
  let recordID: BookishRecordID

  /// The datastore coordinator used to resolve the linked record.
  let harness: BookishUIStateService

  /// The application-owned command boundary used to push the linked record.
  @Environment(BookishEngine.self) private var commander

  /// The resolved visual metadata for the link.
  @State private var presentation: BookishRecordLinkPresentation?

  /// The button label and navigation action for the linked record.
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

  /// Pushes the linked record onto the detail navigation stack.
  private func navigate() {
    commander.performWithoutWaiting(NavigateToRecordCommand(recordID: recordID))
  }

  /// Identifies changes that require link metadata to be resolved again.
  private var taskID: String {
    "\(recordID.rawValue)-\(harness.revision)"
  }

  /// Resolves the link name, thumbnail image, and kind icon.
  private func loadPresentation() async {
    do {
      guard let record = try await harness.navigation.storageService.record(id: recordID) else {
        presentation = nil
        return
      }

      presentation = BookishRecordLinkPresentation(
        record: record,
        placeholderSystemImage: try await harness.presentation.recordKindMetadata(for: record.kind)?
          .string(BookishRecordKey.icon) ?? "doc")
    } catch {
      commander.statusService.report(error: error)
    }
  }
}
