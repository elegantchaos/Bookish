// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Injects Bookish services into content managed by the application shell.
struct BookishEnvironmentInjector: ViewModifier {
  /// Navigation service exposed to datastore SwiftUI content.
  let navigation: BookishNavigationService

  /// Command boundary exposed to datastore SwiftUI content.
  let engine: BookishEngine

  /// Adds the navigation service to the SwiftUI environment.
  func body(content: Content) -> some View {
    content
      .environment(navigation)
      .environment(\.bookishCommandCentre, engine)
  }
}
