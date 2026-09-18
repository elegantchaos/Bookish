// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Settings
import SwiftUI

/// Controls visibility of optional and diagnostic app features.
struct GeneralSettingsView: View {
  /// Whether advanced controls are visible.
  @AppStorage(.isAdvancedMode) private var isAdvancedMode

  /// Whether developer diagnostics are visible.
  @AppStorage(.isDeveloperMode) private var isDeveloperMode

  /// The settings form.
  var body: some View {
    Form {
      Section {
        Toggle("Advanced Mode", isOn: $isAdvancedMode)
        Toggle("Developer Mode", isOn: $isDeveloperMode)
          .disabled(!isAdvancedMode)
      }
    }
    .formStyle(.columns)
    .fixedSize(horizontal: false, vertical: true)
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}

#Preview {
  GeneralSettingsView()
}
