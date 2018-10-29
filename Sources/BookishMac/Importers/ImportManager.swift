// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions

class ImportManager {
    private var importers: [String:Importer] = [:]
    private var sessions: [ImportSession] = []
    
    var sortedImporters: [Importer] {
        return importers.sorted(by: { return $0.key < $1.key }).map({ $0.value })
    }
    
    init() {
        // TODO: build this dynamically
        register(importer: DeliciousLibraryImporter(manager: self))
    }
    
    func register(importer: Importer) {
        importers[importer.name] = importer
    }
    
    func importer(named: String) -> Importer? {
        return importers[named]
    }
    
    func run(importer: Importer, for context: NSManagedObjectContext, url: URL, completion: @escaping ImportSession.Completion) {
        let session = importer.makeSession(for: context, url: url, completion: completion)
        sessions.append(session)
        session.run()
    }
    
    func selectFile(for importer: Importer, document: CollectionDocument, completion: @escaping (URL) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        if let window = document.windowControllers.first?.window {
            panel.beginSheetModal(for: window) { (response) in
                if let url = panel.url {
                    completion(url)
                }
            }
        } else {
            panel.runModal()
            if let url = panel.url {
                completion(url)
                document.makeWindowControllers()
                document.showWindows()
            }
        }
    }

}
