// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions

class ImportManager {
    private var importers: [String:Importer] = [:]
    
    var sortedImporters: [Importer] {
        return importers.sorted(by: { return $0.key < $1.key }).map({ $0.value })
    }
    
    init() {
        // TODO: build this dynamically
        register(importer: Importer(name: "test"))
        register(importer: DeliciousLibraryImporter())
    }
    
    func register(importer: Importer) {
        importers[importer.name] = importer
    }
    
    func importer(named: String) -> Importer? {
        return importers[named]
    }
    

}
