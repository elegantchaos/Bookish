// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 25/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import Observation

/// Owns presentation of the iOS settings sheet.
@MainActor
public final class BookishSettingsPresentationService {
  /// Presents the settings sheet through commands.
  @MainActor
  public protocol API: AnyObject {
    /// Opens the settings sheet.
    func openSettings()
    /// Closes the settings sheet.
    func closeSettings()
  }

  @MainActor
  public protocol Provider: CommandCentre {
    var settingsPresentationService: any API { get }
  }

  @MainActor
  @Observable
  public final class State {
    /// Whether the settings sheet is visible.
    public var isShowingSettings = false

    fileprivate init() {}
  }

  public let state = State()

  /// Creates a settings presentation service with the sheet hidden.
  public init() {}
}

extension BookishSettingsPresentationService: BookishSettingsPresentationService.API {
  public func openSettings() {
    state.isShowingSettings = true
  }

  public func closeSettings() {
    state.isShowingSettings = false
  }
}

extension BookishEngine: BookishSettingsPresentationService.Provider {}
