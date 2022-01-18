// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporterSamples
import SwiftUI
import BookishImporter

struct ImportMenu: View {
    @EnvironmentObject var fileController: FilePickerController
    @EnvironmentObject var importController: ImportController
    @EnvironmentObject var statusController: StatusController
    
    var body: some View {
        Menu("Import") {
            Button(action: handleImportSmall) { Text("Delicious Library Small Sample") }
            Button(action: handleImportFull) { Text("Delicious Library Full Sample") }
            Button(action: handleRequestImportDelicious) { Text("From Delicious Library…") }
            Button(action: handleRequestImportInterchange) { Text("From Bookish Export…") }
        }
    }

    func handleRequestImportDelicious() {
        fileController.importContentTypes = [.xml]
        fileController.chooseFileToImport { result in
            switch result {
                case .success(let url):
                    url.accessSecurityScopedResource { url in
                        importController.import(from: url)
                    }

                case .failure(let error):
                    statusController.notify(error)
            }
        }
    }

    func handleRequestImportInterchange() {
        fileController.importContentTypes = [BookishInterchangeDocument.bookishType]
        fileController.chooseFileToImport { result in
            switch result {
                case .success(let url):
                    url.accessSecurityScopedResource { url in
                        importController.import(from: url)
                    }

                case .failure(let error):
                    statusController.notify(error)
            }
        }
    }

    func handleImportSmall() {
        importController.import(from: BookishImporter.urlForSample(withName: "DeliciousSmall"))
    }

    func handleImportFull() {
        importController.import(from: BookishImporter.urlForSample(withName: "DeliciousFull"))
    }
}
