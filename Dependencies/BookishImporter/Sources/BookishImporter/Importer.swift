// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Files
import Foundation
import Localization

public class Importer {
    public let name: String
    public weak var manager: ImportManager?
    public class var identifier: String { return "import" }

    public init(_ name: String) {
        self.name = name
    }
        
    public var fileTypes: [String]? {
        return nil
    }
    
    public var panelPrompt: String {
        let identifier = type(of:self).identifier
        var string = "\(identifier).prompt".localized
        if string == "\(identifier).prompt" {
            string = "importer.prompt".localized
        }
        return string
    }

    public var panelMessage: String {
        let identifier = type(of:self).identifier
        var string = "\(identifier).message".localized
        if string == "\(identifier).message" {
            string = "importer.message".localized
        }
        return string
    }

    internal func makeSession(delegate: ImportDelegate) -> ImportSession? {
        return nil
    }

    internal func makeSession(importing url: URL, delegate: ImportDelegate) -> URLImportSession? {
        return nil
    }

    internal func makeSession(importing dictionaries: [[String:Any]], delegate: ImportDelegate) -> DictionariesImportSession? {
        return nil
    }
}
