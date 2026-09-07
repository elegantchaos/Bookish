// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

public struct BookishSettingsView: View {
  public init() {
  }

  public var body: some View {
    TabView {
      Tab("General", systemImage: "gear") {
        GeneralSettingsView()
      }
      Tab("Advanced", systemImage: "star") {
        //                AdvancedSettingsView()
      }
    }
    .scenePadding()
    .frame(maxWidth: 350, minHeight: 100)
  }
}
