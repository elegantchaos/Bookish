// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCapture
import SwiftUI

/// Lists the recognition result in the lower, independently scrolling capture pane.
struct BookCaptureCandidateList: View {
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
