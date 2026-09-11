// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import SwiftUI

#if os(macOS)
  import AppKit
#else
  import UIKit
#endif

/// Displays a compact preview of the image used by the scanning workflow.
struct BookRecognitionImagePreview: View {
  /// The selected image data to display.
  let imageData: Data

  var body: some View {
    previewImage
      .resizable()
      .scaledToFill()
      .frame(width: 256, height: 256)
      .clipShape(.rect(cornerRadius: 6))
      .accessibilityLabel("Selected image preview")
  }

  /// Converts the supplied data into a platform-native SwiftUI image.
  private var previewImage: Image {
    #if os(macOS)
      Image(nsImage: NSImage(data: imageData) ?? .init())
    #else
      Image(uiImage: UIImage(data: imageData) ?? .init())
    #endif
  }
}
