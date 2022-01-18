// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Files
import Foundation
import Localization
import UniformTypeIdentifiers

open class Importer {
    public static let defaultSource = "default"
    
    public weak var manager: ImportManager?
    open class var id: String { return "import" }

    public init() {
    }
        
    open var fileTypes: [UTType]? {
        return nil
    }
    
    public var panelPrompt: String {
        let identifier = type(of:self).id
        var string = "\(identifier).prompt".localized
        if string == "\(identifier).prompt" {
            string = "importer.prompt".localized
        }
        return string
    }

    public var panelMessage: String {
        let identifier = type(of:self).id
        var string = "\(identifier).message".localized
        if string == "\(identifier).message" {
            string = "importer.message".localized
        }
        return string
    }

    open func makeSession(source: Any, delegate: ImportDelegate) -> ImportSession? {
        return nil
    }
}

extension Importer: Identifiable {
    open var id: String { Self.id }
}
