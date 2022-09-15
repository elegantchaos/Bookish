// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 12/01/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import SwiftUI

struct ExportButton: View {
    @EnvironmentObject var fileController: FilePickerController
    @EnvironmentObject var exporter: ExportController
    @Environment(\.recordViewer) var container: RecordViewer?

    var body: some View {
        if let _ = container {
            Button(action: handleExport) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
        }
    }

    func handleExport() {
        if let root = container?.container {
            fileController.chooseLocationToExport(BookishInterchangeDocument(root, exporter: exporter)) { result in
                switch result {
                    case .success:
                        break
                        
                    case .failure(let error):
                        print(error)
                }
            }
        }
    }
}
