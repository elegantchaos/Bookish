// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Codex on 09/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PhotosUI
import SwiftUI
import BookishCapture

/// Lets the user choose a book-shelf image and review recognizer candidates.
struct BookCaptureView: View {
  @State private var selectedPhoto: PhotosPickerItem?
  @Environment(BookishCommander.self) private var commander

  /// The observable recognition workflow displayed by this view.
  @Environment(BookishRecognitionService.self) private var recognition

  var body: some View {
    @Bindable var recognition = recognition
    return List {
        Section {
          HStack(alignment: .top) {
            VStack(alignment: .leading) {
              HStack {
                Picker(
                  "Recognition Provider",
                  selection: $recognition.recognizerID
                ) {
                  ForEach(recognition.recognizers, id: \.id) { provider in
                    Text(provider.label).tag(provider.id)
                  }
                }
                .disabled(recognition.isRecognizing)
                
                Spacer()
              }

              PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Choose Image", systemImage: "photo.badge.plus")
              }
              .disabled(recognition.isRecognizing)

              commander.button(UseBookRecognitionExampleImageCommand())
            }
            Spacer()
            if let imageData = recognition.imageData {
              BookRecognitionImagePreview(imageData: imageData)
            }
          }
        } header: {
          Text("Image")
        } footer: {
          Text(recognition.recognizer.description)
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
              Toggle(
                isOn: candidateSelection(
                  for: candidate,
                  recognition: recognition
                )
              ) {
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
      .navigationTitle("Capture")
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

  /// Binds one candidate's visible toggle to the workflow's selected identifiers.
  private func candidateSelection(
    for candidate: BookRecognitionCandidate,
    recognition: BookishRecognitionService
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
