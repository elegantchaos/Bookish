// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Logger


open class PersistentDocument: NSPersistentDocument {
    let modelChannel = Logger("Model")
    override open var managedObjectModel: NSManagedObjectModel {
        get {
            if let url = Bundle(for: PersistentDocument.self).url(forResource: "Document", withExtension: "momd") {
                if let model = NSManagedObjectModel(contentsOf: url) {
                    modelChannel.debug("Loaded model")
                    return model
                }
            }
            fatalError("boom")
        }
    }
}
