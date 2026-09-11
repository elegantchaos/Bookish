// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Injects Bookish services into content managed by the application shell.
struct BookishEnvironmentInjector: ViewModifier {
  /// Command boundary exposed to datastore SwiftUI content.
  let engine: BookishEngine

  /// Adds the command boundary and observable read services to the SwiftUI environment.
  func body(content: Content) -> some View {
    content
      .environment(engine.uiState)
      .environment(engine.navigation)
      .environment(engine.storage)
      .environment(engine.presentationService)
      .environment(engine.status)
      .environment(engine.recognition)
      .environment(engine)
  }
}
