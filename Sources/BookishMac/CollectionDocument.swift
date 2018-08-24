// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa
import BookishModel

class CollectionDocument: PersistentDocument {
    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        let viewModel = CollectionDocumentViewModel(document: self)
        let windowController = Application.sharedInstance.documentWindowControllerFactory.instantiateController(for: viewModel)
        self.addWindowController(windowController)
    }

}
