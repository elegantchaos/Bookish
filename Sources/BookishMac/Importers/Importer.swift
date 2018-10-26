// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

class Importer {
    let name: String
    
    init(name: String) {
        self.name = name
    }
    
    var canImportFromDefaultLocation : Bool {
        return false
    }
    
    func canImport(from url: URL) -> Bool {
        return false
    }
    
    func run() {
        fatalError("subclass should have overridden the run method")
    }
}
