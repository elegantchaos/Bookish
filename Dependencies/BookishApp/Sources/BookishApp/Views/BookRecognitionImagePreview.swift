// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import SwiftUI

/// Displays the image selected for the recognition workflow using a specified layout policy.
struct BookRecognitionImagePreview: View {
  /// The selected image data to display.
  let imageData: Data

  /// The preview's layout policy.
  let sizing: BookRecognitionImagePreviewSizing

  /// The image decoded from `imageData` for SwiftUI presentation.
  @State private var previewImage = Image(systemName: "photo")

  var body: some View {
    Group {
      switch sizing {
      case .compact:
        previewImage
          .resizable()
          .scaledToFill()
          .frame(width: 128, height: 128)

      case .flexible:
        previewImage
          .resizable()
          .scaledToFit()
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
          .frame(minHeight: 64, idealHeight: 128)
      }
    }
    .clipShape(.rect(cornerRadius: 6))
    .accessibilityLabel("Selected image preview")
    .task(id: imageData) {
      await loadPreviewImage()
    }
  }

  /// Decodes the selected image away from SwiftUI's body evaluation path.
  private func loadPreviewImage() async {
    let image = await Task.detached(priority: .userInitiated) {
      BookRecognitionPreviewImageLoader.image(from: imageData)
    }
    .value
    guard Task.isCancelled == false else { return }
    previewImage = image
  }
}

#Preview("Compact") {
  BookRecognitionImagePreview(
    imageData: BookRecognitionImagePreview.exampleImageData,
    sizing: .compact
  )
}

#Preview("Flexible") {
  BookRecognitionImagePreview(
    imageData: BookRecognitionImagePreview.exampleImageData,
    sizing: .flexible
  )
  .frame(width: 320, height: 180)
}

extension BookRecognitionImagePreview {
  /// The bundled example image used by the preview configurations.
  fileprivate static let exampleImageData =
    Bundle.module.url(
      forResource: "CaptureGoodExample",
      withExtension: "JPG"
    )
    .flatMap { try? Data(contentsOf: $0) } ?? .init()
}
