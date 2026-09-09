// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 09/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

/// Displays the placeholder for a top-level Bookish workflow.
struct BookishMainSectionView: View {
  /// The selected workflow to describe.
  let section: BookishMainSection

  /// The placeholder presentation for the selected workflow.
  var body: some View {
    ContentUnavailableView(
      section.title,
      systemImage: section.systemImage,
      description: Text(section.placeholderDescription)
    )
    .navigationTitle(section.title)
  }
}

#Preview {
  BookishMainSectionView(section: .scanning)
}
