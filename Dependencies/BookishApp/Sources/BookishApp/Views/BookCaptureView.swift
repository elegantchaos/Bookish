// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Codex on 09/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Lets the user choose a book-shelf image and review recognizer candidates.
struct BookCaptureView: View {
  /// The Photos picker item selected by the user.
  @State private var selectedPhoto: PhotosPickerItem?

  /// Whether the image-file importer is presented.
  @State private var isImportingImage = false

  /// The command boundary used to update the recognition workflow.
  @Environment(BookishCommander.self) private var commander

  /// The service used to report image-file loading failures.
  @Environment(BookishStatusService.self) private var statusService

  var body: some View {
    BookCaptureLayout(
      selectedPhoto: $selectedPhoto,
      isImportingImage: $isImportingImage
    )
    .navigationTitle("Capture")
    .fileImporter(
      isPresented: $isImportingImage,
      allowedContentTypes: [.image],
      onCompletion: selectImageFile
    )
    .task(id: selectedPhoto) {
      guard let selectedPhoto else { return }
      let imageData = try? await selectedPhoto.loadTransferable(
        type: Data.self
      )
      commander.perform(
        SelectBookRecognitionImageCommand(imageData: imageData)
      )
    }
  }

  /// Loads a selected image file into the recognition workflow.
  private func selectImageFile(_ result: Result<URL, Error>) {
    switch result {
    case .success(let url):
      let accessingSecurityScopedResource = url.startAccessingSecurityScopedResource()
      defer {
        if accessingSecurityScopedResource {
          url.stopAccessingSecurityScopedResource()
        }
      }

      do {
        let imageData = try Data(contentsOf: url)
        commander.perform(
          SelectBookRecognitionImageCommand(imageData: imageData)
        )
      } catch {
        statusService.report(error: error)
      }

    case .failure(let error):
      statusService.report(error: error)
    }
  }

}

#Preview {
  let engine = BookishEngine()
  NavigationStack {
    BookCaptureView()
  }
  .modifier(BookishEnvironmentInjector(engine: engine))
}
