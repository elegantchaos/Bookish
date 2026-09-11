// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishRecord
import Commands
import CommandsUI
import Icons

/// Selects a browser index by its stable record identifier.
public struct SelectRecordIndexCommand<Centre: BookishNavigationProvider>: CommandWithUI {
  public typealias ResultType = Void

  public let id: String
  private let recordIndexID: BookishRecordID

  /// Creates a command that selects a browser index.
  public init(recordIndexID: BookishRecordID) {
    self.id = "datastore.navigation.record-index.\(recordIndexID.rawValue)"
    self.recordIndexID = recordIndexID
  }

  public func availability(centre _: Centre) -> CommandAvailability {
    .enabled
  }

  public func name(centre _: Centre) -> String {
    "Select Record Index"
  }

  public func icon(centre _: Centre) -> Icon {
    Icon("list.bullet")
  }

  public func help(centre _: Centre) -> String? {
    "Select a record index in the datastore browser."
  }

  public func perform(centre: Centre) async throws {
    try await centre.navigationService.select(recordIndexID: recordIndexID)
  }
}
