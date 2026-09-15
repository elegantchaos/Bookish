// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PhotosUI
import SwiftUI

/// Shows the capture controls beside the image preview in the upper pane.
struct BookCaptureImageControls: View {
  /// The Photos picker item selected by the user.
  @Binding var selectedPhoto: PhotosPickerItem?

  /// Whether the image-file importer is presented.
  @Binding var isImportingImage: Bool

  /// The command boundary used to perform capture actions.
  @Environment(BookishCommander.self) private var commander

  /// The observable recognition workflow displayed by this view.
  @Environment(BookishRecognitionService.self) private var recognition

  var body: some View {
    VStack(alignment: .leading) {
      LabeledContent("Method") {
        Menu {
          ForEach(recognition.recognizers, id: \.id) { recognizer in
            commander.button(SelectRecognizerCommand(provider: recognizer.id)) {
              HStack {
                Image(systemName: "checkmark")
                  .opacity(recognizer.id == recognition.recognizerID ? 1 : 0)
                Text(recognizer.label)
              }
            }
            .disabled(recognizer.isSupported == false)
          }
        } label: {
          Text(recognition.recognizer.label)
        }
      }
      .disabled(recognition.isRecognizing)

      Menu {
        PhotosPicker(selection: $selectedPhoto, matching: .images) {
          Text("From Photos…")
        }

        Button("From File…", action: chooseImageFile)

        commander.button(UseBookRecognitionExampleImageCommand()) {
          Text("Use Example")
        }
      } label: {
        Label("Choose Image", systemImage: "photo.badge.plus")
      }
      .disabled(recognition.isRecognizing)

      commander.button(CaptureBooksCommand())
    }
  }

  /// Presents a file picker for an image outside the photo library.
  private func chooseImageFile() {
    isImportingImage = true
  }
}
