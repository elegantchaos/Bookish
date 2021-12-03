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
        return instances.sorted(by: { return $0.name < $1.name })
    }
    
    public init(_ importersToRegister: [Importer]) {
        register(importersToRegister)
    }
    
    public func register(_ importersToRegister: [Importer]) {
        for importer in importersToRegister {
            importerChannel.log("Registered \(importer.name)")
            importers[type(of: importer).id] = importer
            importer.manager = self
        }
    }
    
    public func importer(identifier: String) -> Importer? {
        return importers[identifier]
    }
    
    public func importFrom(_ url: URL, delegate: ImportDelegate) {
        for importer in sortedImporters {
            if let session = importer.makeSession(importing: url, delegate: delegate) {
                session.performImport()
                break
            }
        }
        
        delegate.noImporter()
    }
    
    public func importFrom(_ dictionaries: [[String:Any]], delegate: ImportDelegate) {
        for importer in sortedImporters {
            if let session = importer.makeSession(importing: dictionaries, delegate: delegate) {
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
