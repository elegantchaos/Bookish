// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/12/21.
//  All code (c) 2021 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishImporter
import SwiftUI

class ImportController: ObservableObject {
    let importer: ImportManager
    let model: ModelController
    
    @Published var importRequested = false
    @Published var importProgress: ImportProgress?
    
    init(model: ModelController) {
        self.model = model
        self.importer = ImportManager([
            DeliciousLibraryImporter(),
            DictionariesImporter(),
            BookRecordsImporter()
        ])
    }
    
    func `import`(from source: Any) {
        model.stack.onBackground { context in
            let delegate = ImportHandler(model: self.model, importController: self, context: context)
            self.importer.importFrom(source, delegate: delegate)
        }
    }

}
