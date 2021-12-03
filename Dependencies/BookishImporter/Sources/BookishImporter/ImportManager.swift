// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Logger

let importerChannel = Channel("com.elegantchaos.bookish.Importer")

public class ImportManager {
    private var importers: [String:Importer] = [:]
    private var sessions: [ImportSession] = []
    
    public var sortedImporters: [Importer] {
        let instances = importers.values
        return instances.sorted(by: { return $0.id < $1.id })
    }
    
    public init(_ importersToRegister: [Importer]) {
        register(importersToRegister)
    }
    
    public func register(_ importersToRegister: [Importer]) {
        for importer in importersToRegister {
            importerChannel.log("Registered \(importer.id)")
            importers[type(of: importer).id] = importer
            importer.manager = self
        }
    }
    
    public func importer(identifier: String) -> Importer? {
        return importers[identifier]
    }
    
    public func importFrom(_ source: Any, delegate: ImportDelegate) {
        for importer in sortedImporters {
            if let session = importer.makeSession(source: source, delegate: delegate) {
                session.performImport()
                break
            }
        }
        
        delegate.noImporter()
    }

    func sessionWillBegin(_ session: ImportSession) {
        sessions.append(session)
    }
    
    func sessionDidFinish(_ session: ImportSession) {
        if let index = sessions.firstIndex(of: session) {
            sessions.remove(at: index)
        }
    }

}
