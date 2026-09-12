// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Commands
import CommandsUI
import Observation
import SwiftUI

/// Provides the intentionally small command surface available to SwiftUI views.
///
/// The application engine remains the concrete command centre used by commands.
/// This façade only forwards command dispatch and command UI helpers, preventing
/// views from reaching service-provider APIs through the command environment.
@MainActor
@Observable
final class BookishCommander {
  /// The engine that owns command execution and its service providers.
  @ObservationIgnored private weak var attachedEngine: BookishEngine?

  /// Creates an unconfigured command façade.
  init() {
  }

  /// Connects the façade to its owning engine exactly once.
  func attach(to engine: BookishEngine) {
    precondition(attachedEngine == nil, "A BookishCommander can only be attached once.")
    attachedEngine = engine
  }

  /// Performs a command asynchronously and reports failures through the engine.
  @discardableResult
  func performWithoutWaiting<C: Command>(_ command: C) -> Task<Void, Never>
  where C.Centre == BookishEngine {
    engine.performWithoutWaiting(command)
  }

  /// Returns a labelled button for a command.
  @ViewBuilder
  func button<C: CommandWithUI>(_ command: C, role: ButtonRole? = nil) -> some View
  where C.Centre == BookishEngine {
    engine.button(command, role: role)
  }

  /// Returns a command button with custom content.
  @ViewBuilder
  func button<C: CommandWithUI, Content: View>(
    _ command: C,
    role: ButtonRole? = nil,
    content: @escaping () -> Content
  ) -> some View
  where C.Centre == BookishEngine {
    engine.button(command, role: role, content: content)
  }

  /// Returns a toolbar item for a command.
  @ToolbarContentBuilder
  func toolbarItem<C: CommandWithUI>(
    _ command: C,
    placement: ToolbarItemPlacement = .automatic
  ) -> some ToolbarContent
  where C.Centre == BookishEngine {
    engine.toolbarItem(command, placement: placement)
  }

  /// Returns the attached engine, failing only for invalid composition.
  private var engine: BookishEngine {
    guard let attachedEngine else {
      fatalError("BookishCommander must be attached before use.")
    }

    return attachedEngine
  }
}
