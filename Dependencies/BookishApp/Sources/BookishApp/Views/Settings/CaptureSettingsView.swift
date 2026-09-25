// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/09/2026.
//  Copyright © 2026 Elegant Chaos Limited. All rights reserved.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Settings
import SwiftUI

/// Controls visibility of optional and diagnostic app features.
struct CaptureSettingsView: View {
  @Environment(BookishCommander.self) var commander
  @Environment(BookishRecognitionService.State.self) var recognition

  /// Whether to scan for barcodes when using the camera in the capture mode.
  @AppStorage(.scanForBarcodes) private var scanForBarcodes

  /// The settings form.
  var body: some View {
    let currentRecognitionProvider = recognition.selectedRecognitionProviderID

    return Form {
      Section {
        LabeledContent("Barcodes") {
          Toggle("Scan For Barcodes", isOn: $scanForBarcodes)
        }

        LabeledContent("Capture Method") {
          VStack(alignment: .leading) {
            Menu {
              ForEach(recognition.recognitionProviders, id: \.id) { recognitionProvider in
                commander.button(SelectRecognitionProviderCommand(recognitionProvider.id)) {
                  HStack {
                    Image(systemName: "checkmark")
                      .opacity(recognitionProvider.id == currentRecognitionProvider ? 1 : 0)
                    Text(recognitionProvider.label)
                  }
                }
                .disabled(!recognitionProvider.isSupported)
              }
            } label: {
              Text(recognition.recognitionProvider.label)
            }

            Text(recognition.recognitionProvider.description)
              .font(.footnote)
              .foregroundStyle(.secondary)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
      .disabled(recognition.isRecognizing)
    }
    .formStyle(.columns)
    .fixedSize(horizontal: false, vertical: true)
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }
}

#Preview {
  let engine = BookishEngine()
  CaptureSettingsView()
    .modifier(BookishEnvironmentInjector(engine: engine))
}
