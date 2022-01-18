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

    @Published var importProgress: ImportProgress?

    init(model: ModelController) {
        self.model = model
        self.importer = ImportManager([
            DeliciousLibraryImporter(),
            DictionariesImporter(),
            BookRecordsImporter(),
            BookishInterchangeImporter(),
        ])
    }
    
    var isImporting: Bool {
        importProgress != nil
    }
    
    func `import`(from source: Any) {
        ImportHandler.run(importer: importer, source: source, model: model, importController: self)
    }
}
