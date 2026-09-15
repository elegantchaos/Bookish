// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PhotosUI
import SwiftUI

/// Displays the controls and selected image across the top of the capture workflow.
struct BookCaptureTopPane: View {
  /// The Photos picker item selected by the user.
  @Binding var selectedPhoto: PhotosPickerItem?

  /// Whether the image-file importer is presented.
  @Binding var isImportingImage: Bool

  /// The observable recognition workflow displayed by this view.
  @Environment(BookishRecognitionService.self) private var recognition

  /// The current horizontal size class used to choose the preview layout policy.
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var body: some View {
    HStack(alignment: .top) {
      BookCaptureImageControls(
        selectedPhoto: $selectedPhoto,
        isImportingImage: $isImportingImage
      )

      Spacer()

      if let imageData = recognition.imageData {
        BookRecognitionImagePreview(
          imageData: imageData,
          sizing: horizontalSizeClass == .compact ? .compact : .flexible
        )
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .padding()
  }
}
