// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

class DeliciousLibraryImporter: Importer {
    init() {
        super.init(name: "Delicious Library")
    }
    
    override var canImportFromDefaultLocation: Bool {
        return true
    }
    
    override func run() {
        print("importing from delicious library")
    }
}
