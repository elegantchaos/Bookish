// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Settings
import SwiftUI

struct GeneralSettingsView: View {
  @AppStorage(.isAdvancedMode) var isAdvancedMode
  @AppStorage(.isDeveloperMode) var isDeveloperMode

  var body: some View {
    Form {
      Toggle("Advanced Mode", isOn: $isAdvancedMode)
      Toggle("Developer Mode", isOn: $isDeveloperMode)
        .disabled(!isAdvancedMode)
    }
  }
}
