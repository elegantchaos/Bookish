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
    
    internal func makeSession(importing url: URL, into context: NSManagedObjectContext, completion: @escaping ImportSession.Completion) -> ImportSession {
        let session = ImportSession(importer: self, context: context, url: url, completion: completion)
        return session
    }
    
    func run(importing url: URL, into context: NSManagedObjectContext, completion: @escaping ImportSession.Completion) {
        let session = makeSession(importing: url, into: context, completion: completion)
        session.performImport()
    }
}
