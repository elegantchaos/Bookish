// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Codex on 09/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCapture
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

/// Lets the user choose a book-shelf image and review recognizer candidates.
struct BookCaptureView: View {
  @State private var selectedPhoto: PhotosPickerItem?
  @State private var isImportingImage = false
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
      commander.performWithoutWaiting(
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
        commander.performWithoutWaiting(
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

/// Arranges the capture workspace above a scrollable candidate list.
private struct BookCaptureLayout: View {
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

/// Displays the controls and selected image across the top of the capture workflow.
private struct BookCaptureTopPane: View {
  /// The Photos picker item selected by the user.
  @Binding var selectedPhoto: PhotosPickerItem?

  /// Whether the image-file importer is presented.
  @Binding var isImportingImage: Bool

  /// The observable recognition workflow displayed by this view.
  @Environment(BookishRecognitionService.self) private var recognition

  var body: some View {
    HStack(alignment: .top) {
      BookCaptureImageControls(
        selectedPhoto: $selectedPhoto,
        isImportingImage: $isImportingImage
      )

      Spacer()

      if let imageData = recognition.imageData {
        #if os(macOS)
          BookRecognitionResizableImagePreview(imageData: imageData)
        #else
          BookRecognitionImagePreview(imageData: imageData)
        #endif
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .padding()
  }
}

/// Shows the capture controls beside the image preview in the upper pane.
private struct BookCaptureImageControls: View {
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
      Menu {
        ForEach(recognition.recognizers, id: \.id) { recognizer in
          commander.button(SelectRecognizerCommand(provider: recognizer.id)) {
            Text(recognizer.label)
          }
        }
      } label: {
        LabeledContent("Choose Method") {
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

/// Lists the recognition result in the lower, independently scrolling capture pane.
private struct BookCaptureCandidateList: View {
  /// The command boundary used to perform candidate actions.
  @Environment(BookishCommander.self) private var commander

  /// The observable recognition workflow displayed by this view.
  @Environment(BookishRecognitionService.self) private var recognition

  var body: some View {
    List {
      if recognition.isRecognizing {
        ProgressView("Identifying books…")
      }

      if let error = recognition.error {
        Section("Couldn’t Identify Books") {
          Text(error.localizedDescription)
            .foregroundStyle(.red)
        }
      }

      if recognition.candidates.isEmpty == false {
        Section("Candidates") {
          HStack {
            Spacer()
            commander.button(SelectAllRecognizedBooksCommand()) {
              Text("Select All")
            }
            .controlSize(.small)
            commander.button(DeselectAllRecognizedBooksCommand()) {
              Text("Deselect All")
            }
            .controlSize(.small)
          }

          ForEach(recognition.candidates) { candidate in
            Toggle(isOn: candidateSelection(for: candidate)) {
              VStack(alignment: .leading, spacing: 4) {
                Text(candidate.title)
                  .font(.headline)
                if candidate.authors.isEmpty == false {
                  Text(candidate.authors.formatted(.list(type: .and)))
                    .foregroundStyle(.secondary)
                }
                Text(
                  candidate.confidence,
                  format: .percent.precision(.fractionLength(0))
                )
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityLabel(
                  "Recognition confidence \(candidate.confidence, format: .percent)"
                )
              }
            }
          }

          HStack {
            Spacer()
            commander.button(AddSelectedRecognizedBooksCommand())
          }
        }
      }
    }
  }

  /// Binds one candidate's visible toggle to the workflow's selected identifiers.
  private func candidateSelection(
    for candidate: BookRecognitionCandidate
  ) -> Binding<Bool> {
    Binding(
      get: { recognition.selectedCandidateIDs.contains(candidate.id) },
      set: { isSelected in
        if isSelected {
          recognition.selectedCandidateIDs.insert(candidate.id)
        } else {
          recognition.selectedCandidateIDs.remove(candidate.id)
        }
      }
    )
  }
}

#Preview {
  let engine = BookishEngine()
  NavigationStack {
    BookCaptureView()
  }
  .modifier(BookishEnvironmentInjector(engine: engine))
}
