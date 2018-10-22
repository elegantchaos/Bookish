// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishCore
import BookishModel
import Logger

let validationChannel = Logger("Validation")

class CollectionWindowController: NSWindowController, DocumentWindowController, ActionContextProvider {
    var viewModel: CollectionDocumentViewModel?
    typealias ViewModel = CollectionDocumentViewModel
    
    var bookIndexController: BookIndexViewController?
    var bookDetailController: BookDetailViewController?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        window?.autorecalculatesKeyViewLoop = false
    }
    
    func provide(context: ActionContext) {
        if let model = viewModel {
            context.info[ActionContext.modelKey] = model.managedObjectContext
            context.info[ActionContext.viewModelKey] = model
            context.info[ActionContext.windowKey] = self
        }
    }
    
    func validateButtons() {
        if let view = window?.contentView {
            view.validateButtons()
        }
    }
    
    @objc func reveal(person: Person) {
        if let model = viewModel {
            model.mode = .people
        }
    }
    
    @objc func reveal(book: Book) {
        if let model = viewModel {
            model.mode = .books
        }
    }
}
