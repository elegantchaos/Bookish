// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 29/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Localization

public class ImportSession: Equatable {
    public static func == (lhs: ImportSession, rhs: ImportSession) -> Bool {
        return lhs === rhs
    }
    
    public typealias Completion = (ImportSession?) -> Void
    
    let importer: Importer
    let monitor: ImportMonitor?
    
    init?(importer: Importer, monitor: ImportMonitor?) {
        self.importer = importer
        self.monitor = monitor
    }
    
    func performImport() {
        let importer = self.importer
        DispatchQueue.global(qos: .userInitiated).async {
            importer.manager.sessionWillBegin(self)
            self.run()
            importer.manager.sessionDidFinish(self)
        }
    }

    internal func run() {
    }
    
    public var title: String {
        let id = type(of: importer).identifier
        let name = "\(id).name".localized
        return "importer.progress.title".localized(with: ["name": name])
    }
}

public class URLImportSession: ImportSession {
    public static func == (lhs: URLImportSession, rhs: URLImportSession) -> Bool {
        return lhs === rhs
    }
    
    let url: URL
    
    init?(importer: Importer, url: URL, monitor: ImportMonitor?) {
        guard FileManager.default.fileExists(atURL: url) else {
            return nil
        }
        
        self.url = url
        super.init(importer: importer, monitor: monitor)
    }
}
