// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import SwiftUI
import UniformTypeIdentifiers

class ImportController: ObservableObject {
    let importer: ImportManager
    let model: ModelController
    
    @Published var importRequested = false
    @Published var importProgress: ImportProgress?
    @Published var importContentTypes: [UTType] = [.xml]
    @Published private var importCompletion: ((_ result: Result<URL,Error>) -> ())?
    
    init(model: ModelController) {
        self.model = model
        self.importer = ImportManager([
            DeliciousLibraryImporter(),
            DictionariesImporter(),
            BookRecordsImporter()
        ])
    }
    
    var isImporting: Bool {
        importProgress != nil
    }
    
    func `import`(from source: Any) {
        ImportHandler.run(importer: importer, source: source, model: model, importController: self)
    }

    func chooseFileToImport(completion: @escaping (_ result: Result<URL,Error>) -> ()) {
        importCompletion = completion
        importRequested = true
    }
    
    func handlePerformImport(_ result: Result<URL,Error>) {
        importCompletion?(result)
        importCompletion = nil
    }
}
