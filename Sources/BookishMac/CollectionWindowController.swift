// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishCore
import BookishModel

class CollectionWindowController: NSWindowController, DocumentWindowController, ActionContextProvider {
    var viewModel: CollectionDocumentViewModel?
    typealias ViewModel = CollectionDocumentViewModel
    
    var bookIndexController: CollectionIndexViewController?
    var bookDetailController: CollectionDetailViewController?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.autorecalculatesKeyViewLoop = false
    }
    
    func provide(context: ActionContext) {
        if let model = viewModel {
            context.info[ActionContext.modelKey] = model
        }
    }
}
