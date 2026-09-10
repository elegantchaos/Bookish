// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Codex on 09/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PhotosUI
import SwiftUI

/// Lets the user choose a book-shelf image and review recognizer candidates.
struct BookScanningView: View {
  @State private var selectedPhoto: PhotosPickerItem?
  @State private var recognition = BookRecognitionViewModel()

  var body: some View {
    List {
      Section {
        Picker("Recognition Provider", selection: $recognition.provider) {
          ForEach(BookRecognitionProvider.allCases) { provider in
            Text(provider.title).tag(provider)
          }
        }
        .disabled(recognition.isRecognizing)

        PhotosPicker(selection: $selectedPhoto, matching: .images) {
          Label("Choose Image", systemImage: "photo.badge.plus")
        }
        .disabled(recognition.isRecognizing)

        Button("Use Example Image", systemImage: "photo") {
          recognition.selectCaptureGoodExample()
        }
        .disabled(recognition.isRecognizing)

        if let imageData = recognition.imageData {
          LabeledContent("Selected Image") {
            Text(Int64(imageData.count), format: .byteCount(style: .file))
              .foregroundStyle(.secondary)
          }
        }

        Button("Identify Books", systemImage: "text.viewfinder") {
          Task {
            await recognition.identifyBooks()
          }
        }
        .disabled(recognition.imageData == nil || recognition.isRecognizing)
      } header: {
        Text("Image")
      } footer: {
        Text(providerDescription)
      }

      if recognition.isRecognizing {
        Section {
          ProgressView("Identifying books…")
        }
      }

      if let error = recognition.error {
        Section("Couldn’t Identify Books") {
          Text(error.localizedDescription)
            .foregroundStyle(.red)
        }
      }

      if recognition.candidates.isEmpty == false {
        Section("Candidates") {
          ForEach(recognition.candidates) { candidate in
            VStack(alignment: .leading, spacing: 4) {
              Text(candidate.title)
                .font(.headline)
              if candidate.authors.isEmpty == false {
                Text(candidate.authors.formatted(.list(type: .and)))
                  .foregroundStyle(.secondary)
              }
              Text(candidate.confidence, format: .percent.precision(.fractionLength(0)))
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel(
                  "Recognition confidence \(candidate.confidence, format: .percent)")
            }
          }
        }
      }
    }
    .navigationTitle("Scanning")
    .task(id: selectedPhoto) {
      guard let selectedPhoto else { return }
      do {
        recognition.selectImage(data: try await selectedPhoto.loadTransferable(type: Data.self))
      } catch {
        recognition.selectImage(data: nil)
      }
    }
  }

  /// Describes where the selected image is processed for the active provider.
  private var providerDescription: String {
    switch recognition.provider {
    case .openAI:
      "The selected image is sent to OpenAI only when you choose Identify Books."
    case .appleOnDevice:
      "Vision and Apple Intelligence process the selected image on this device when you choose Identify Books."
    case .applePrivateCloudCompute:
      "Private Cloud Compute is unavailable in this build until its newer Foundation Models SDK and entitlement are available."
    }
  }
}

#Preview {
  NavigationStack {
    BookScanningView()
  }
}
