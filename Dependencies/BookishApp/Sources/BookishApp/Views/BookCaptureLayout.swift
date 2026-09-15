// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PhotosUI
import SwiftUI

/// Arranges the capture workspace above a scrollable candidate list.
struct BookCaptureLayout: View {
  /// The Photos picker item selected by the user.
  @Binding var selectedPhoto: PhotosPickerItem?

  /// Whether the image-file importer is presented.
  @Binding var isImportingImage: Bool

  var body: some View {
    #if os(macOS)
      VSplitView {
        BookCaptureTopPane(
          selectedPhoto: $selectedPhoto,
          isImportingImage: $isImportingImage
        )
        .frame(minHeight: 64, idealHeight: 128)

        BookCaptureCandidateList()
      }
    #else
      VStack(spacing: 0) {
        BookCaptureTopPane(
          selectedPhoto: $selectedPhoto,
          isImportingImage: $isImportingImage
        )

        BookCaptureCandidateList()
      }
    #endif
  }
}
