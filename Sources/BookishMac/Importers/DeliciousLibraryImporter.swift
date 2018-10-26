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
        // ~/Library/Containers/Data/Library/Application\ Support/Delicious\ Library\ 3/

        for library in FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask) {
            let containers = library.appendingPathComponent("containers")
            let delicious = containers.appendingPathComponent("com.delicious-monster.library3")
            let data = delicious.appendingPathComponent("Data").appendingPathComponent("Application Support").appendingPathComponent("Delicious Library 3")
        }
        return true
    }
    
    override func run() {
        print("importing from delicious library")
    }
}
