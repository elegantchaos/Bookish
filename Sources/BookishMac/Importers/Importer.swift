// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import CoreData

class Importer {
    enum Source {
        case knownLocation
        case userSpecifiedFile
    }
    
    let name: String
    let source: Source
    let manager: ImportManager
    
    init(name: String, source: Source, manager: ImportManager) {
        self.name = name
        self.source = source
        self.manager = manager
    }
    
    var canImport: Bool {
        switch source {
        case .knownLocation:
            if let url = defaultImportLocation {
                return FileManager.default.fileExists(atPath: url.path)
            }
            
        case .userSpecifiedFile:
            return true
        }
        
        return false
    }
    
    var defaultImportLocation: URL? {
        return nil
    }
    
    func run(for document: CollectionDocument) {
        if let context = document.managedObjectContext {
            let completion = { (url: URL) in
                self.run(with: url, for: context)
            }
            
            if source == .knownLocation {
                if let url = defaultImportLocation {
                    completion(url)
                }
            } else {
                manager.selectFile(for: self, document: document, completion: completion)
            }
        }
    }
    
    func run(with url: URL, for collection: NSManagedObjectContext) {
        fatalError("subclass should have overridden the run method")
    }
}
