// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import ImageIO
import SwiftUI

/// Decodes recognition image data into a cross-platform SwiftUI image.
enum BookRecognitionPreviewImageLoader {
  /// Decodes a SwiftUI image from supplied image data.
  static func image(from imageData: Data) -> Image {
    guard
      let source = CGImageSourceCreateWithData(imageData as CFData, nil),
      let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
      return Image(systemName: "photo")
    }

    return Image(
      cgImage,
      scale: 1,
      orientation: orientation(for: source),
      label: Text("Selected image preview")
    )
  }

  /// Returns the SwiftUI orientation corresponding to the source image metadata.
  private static func orientation(for source: CGImageSource) -> Image.Orientation {
    guard
      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
      let rawValue = (properties[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value,
      let orientation = CGImagePropertyOrientation(rawValue: rawValue)
    else {
      return .up
    }

    return switch orientation {
    case .up:
      .up
    case .upMirrored:
      .upMirrored
    case .down:
      .down
    case .downMirrored:
      .downMirrored
    case .left:
      .left
    case .leftMirrored:
      .leftMirrored
    case .right:
      .right
    case .rightMirrored:
      .rightMirrored
    @unknown default:
      .up
    }
  }
}
