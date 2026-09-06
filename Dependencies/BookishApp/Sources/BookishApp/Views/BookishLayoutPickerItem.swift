// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import SwiftUI

struct BookishLayoutPickerItem: View {
  let layoutID: BookishRecordID
  let harness: BookishHarness

  @State private var name: String?

  var body: some View {
    Text(name ?? layoutID.rawValue)
      .tag(Optional(layoutID))
      .task(id: taskID) {
        await load()
      }
  }

  private var taskID: String {
    "\(layoutID.rawValue)-\(harness.revision)"
  }

  private func load() async {
    do {
      name = try await harness.record(id: layoutID)?.string(BookishRecordKey.name)
    } catch {
      harness.report(error: error)
    }
  }
}
