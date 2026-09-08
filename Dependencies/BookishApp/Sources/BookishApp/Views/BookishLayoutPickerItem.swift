// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import SwiftUI

/// Resolves the display name for one layout picker option.
struct BookishLayoutPickerItem: View {
  /// The identifier of the represented layout.
  let layoutID: BookishRecordID

  /// The datastore coordinator used to resolve the layout.
  let harness: BookishHarness

  /// The command boundary used to report layout-resolution failures.
  @Environment(\.bookishCommandCentre) private var commander

  /// The resolved layout name, when available.
  @State private var name: String?

  /// The tagged picker item.
  var body: some View {
    Text(name ?? layoutID.rawValue)
      .tag(Optional(layoutID))
      .task(id: taskID) {
        await load()
      }
  }

  /// Identifies changes that require the layout name to be resolved again.
  private var taskID: String {
    "\(layoutID.rawValue)-\(harness.revision)"
  }

  /// Resolves the layout name for the picker label.
  private func load() async {
    do {
      name = try await harness.storageService.record(id: layoutID)?.string(BookishRecordKey.name)
    } catch {
      commander?.statusReporter.report(error: error)
    }
  }
}
