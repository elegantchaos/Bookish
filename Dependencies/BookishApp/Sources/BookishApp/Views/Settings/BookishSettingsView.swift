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

      Tab("Capture", systemImage: "camera") {
        CaptureSettingsView()
      }

      Tab("Lookup", systemImage: "magnifyingglass") {
        LookupSettingsView()
      }
    }
    #if os(macOS)
      .frame(minWidth: 520, maxWidth: 800, minHeight: 400)
    #endif
  }
}
