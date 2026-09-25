// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 07/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Settings
import SwiftUI

/// Controls visibility of optional and diagnostic app features.
struct GeneralSettingsView: View {
  /// How much optional and diagnostic functionality is visible.
  @AppStorage(.featureMode) private var featureMode

  /// The settings form.
  var body: some View {
    Form {
      Section {
        BookishFeatureModePicker(selection: $featureMode)
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
