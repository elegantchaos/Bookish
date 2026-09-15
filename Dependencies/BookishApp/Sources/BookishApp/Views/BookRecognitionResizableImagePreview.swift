// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import SwiftUI

#if os(macOS)
  import AppKit
#endif

/// Displays a preview that fills a resizable capture pane.
struct BookRecognitionResizableImagePreview: View {
  /// The selected image data to display.
  let imageData: Data

  var body: some View {
    previewImage
      .resizable()
      .scaledToFit()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .frame(minHeight: 64, idealHeight: 128)
      .clipShape(.rect(cornerRadius: 6))
      .accessibilityLabel("Selected image preview")
  }

  /// Converts the supplied data into a platform-native SwiftUI image.
  private var previewImage: Image {
    Image(nsImage: NSImage(data: imageData) ?? .init())
  }
}
