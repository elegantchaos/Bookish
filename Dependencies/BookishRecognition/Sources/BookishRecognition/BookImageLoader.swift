// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import ImageIO

/// Decodes the first image in recognition input data.
struct BookImageLoader {
  /// Returns the first image frame in the supplied data.
  func image(from imageData: Data) throws -> CGImage {
    guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
      let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
    else {
      throw BookRecognitionError.noReadableBookText
    }
    return image
  }
}
