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
    
    public init() {
        // TODO: build this dynamically - from plugins maybe?
        register([
            DeliciousLibraryImporter(manager: self),
        ])
    }
    
    public func register(_ importersToRegister: [Importer]) {
        for importer in importersToRegister {
            importerChannel.log("Registered \(importer.name)")
            importers[type(of: importer).identifier] = importer
        }
    }
    
    public func importer(identifier: String) -> Importer? {
        return importers[identifier]
    }
    
    public func importFrom(_ url: URL, monitor: ImportMonitor) {
        for importer in sortedImporters {
            if let session = importer.makeSession(importing: url, monitor: monitor) {
                session.performImport()
                break
            }
        }
        
        monitor.noImporter()
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
