// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 29/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import Localization

open class ImportSession: Identifiable {
    public typealias Completion = (ImportSession?) -> Void
    
    public let id = UUID()
    let importer: Importer
    public let delegate: ImportDelegate
    
    public init?(importer: Importer, delegate: ImportDelegate) {
        self.importer = importer
        self.delegate = delegate
    }
    
    func performImport() {
        let importer = self.importer
        DispatchQueue.global(qos: .userInitiated).async {
            importer.manager?.sessionWillBegin(self)
            self.run()
            importer.manager?.sessionDidFinish(self)
        }
    }

    open func run() {
    }
    
    public var source: String {
        return importer.id
    }

    public var title: String {
        let name = "\(id).name".localized
        return "importer.progress.title".localized(with: ["name": name])
    }
}

public class URLImportSession: ImportSession {
    public static func == (lhs: URLImportSession, rhs: URLImportSession) -> Bool {
        return lhs === rhs
    }
    
    let url: URL
    
    init?(importer: Importer, url: URL, delegate: ImportDelegate) {
        guard FileManager.default.fileExists(atURL: url) else {
            return nil
        }
        
        self.url = url
        super.init(importer: importer, delegate: delegate)
    }
}

extension ImportSession: Equatable {
    public static func == (lhs: ImportSession, rhs: ImportSession) -> Bool {
        return lhs.id == rhs.id
    }
}
