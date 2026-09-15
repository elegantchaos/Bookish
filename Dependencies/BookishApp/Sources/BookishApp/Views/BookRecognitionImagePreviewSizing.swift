// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

/// Defines the layout policies available for a book-recognition image preview.
enum BookRecognitionImagePreviewSizing {
  /// Displays a cropped image in a fixed square preview.
  case compact

  /// Displays the complete image in the available preview space.
  case flexible
}
