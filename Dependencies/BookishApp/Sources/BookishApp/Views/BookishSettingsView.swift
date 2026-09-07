// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// The Bookish settings scene content.
public struct BookishSettingsView: View {
  /// Creates the settings content.
  public init() {
  }

  /// The settings tabs.
  public var body: some View {
    TabView {
      Tab("General", systemImage: "gear") {
        GeneralSettingsView()
      }
    }
    .scenePadding()
    .frame(maxWidth: 350, minHeight: 100)
  }
}
