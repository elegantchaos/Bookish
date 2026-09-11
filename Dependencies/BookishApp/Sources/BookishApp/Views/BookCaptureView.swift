// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Codex on 09/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import PhotosUI
import SwiftUI

/// Lets the user choose a book-shelf image and review recognizer candidates.
struct BookCaptureView: View {
  @State private var selectedPhoto: PhotosPickerItem?
  @Environment(\.bookishCommandCentre) private var commander

  var body: some View {
    if let commander {
      @Bindable var recognition = commander.recognition
      List {
        Section {
          HStack(alignment: .top) {
            VStack(alignment: .leading) {
              HStack {
                Picker(
                  "Recognition Provider",
                  selection: providerSelection(
                    for: recognition,
                    commander: commander
                  )
                ) {
                  ForEach(BookRecognitionProvider.allCases) { provider in
                    Text(provider.title).tag(provider)
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
          Text(providerDescription(for: recognition.provider))
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
    } else {
      ProgressView()
        .navigationTitle("Capture")
    }
  }

  /// Binds one candidate's visible toggle to the workflow's selected identifiers.
  private func candidateSelection(
    for candidate: BookRecognitionCandidate,
    recognition: BookRecognitionViewModel
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

  /// Binds the provider picker to the command-backed recognition workflow.
  private func providerSelection(
    for recognition: BookRecognitionViewModel,
    commander: BookishEngine
  ) -> Binding<BookRecognitionProvider> {
    Binding(
      get: { recognition.provider },
      set: { provider in
        commander.performWithoutWaiting(
          SelectBookRecognitionProviderCommand(provider: provider)
        )
      }
    )
  }

  /// Describes where the selected image is processed for the active provider.
  private func providerDescription(for provider: BookRecognitionProvider)
    -> String
  {
    switch provider {
    case .fake:
      "Returns a fixed sample of books without processing the selected image."
    case .ocr:
      "Vision reads text from the selected image before Apple Intelligence identifies books."
    case .openAI:
      "The selected image is sent to OpenAI only when you choose Identify Books."
    case .appleOnDevice:
      "Direct on-device image recognition is unavailable in this build because it requires a newer Foundation Models SDK."
    case .applePrivateCloudCompute:
      "Private Cloud Compute is unavailable in this build until its newer Foundation Models SDK and entitlement are available."
    }
  }
}

#Preview {
  NavigationStack {
    BookCaptureView()
  }
  .environment(\.bookishCommandCentre, BookishEngine())
}
