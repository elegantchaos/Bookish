// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 25/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Chooses how much optional and diagnostic functionality is visible.
struct BookishFeatureModePicker: View {
  /// The selected feature mode.
  @Binding var selection: BookishFeatureMode

  /// The mode picker.
  var body: some View {
    Picker("Mode", selection: $selection) {
      ForEach(BookishFeatureMode.allCases, id: \.self) { mode in
        Text(mode.label).tag(mode)
      }
    }
  }
}
