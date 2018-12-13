// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel
import Logger

let validationChannel = Logger("Validation")

class CollectionWindowController: NSWindowController, NSUserInterfaceValidations, DocumentWindowController, ActionContextProvider {
    var viewModel: CollectionDocumentViewModel?
    typealias ViewModel = CollectionDocumentViewModel
    
    var bookIndexController: BookIndexViewController?
    var personIndexController: PersonIndexViewController?
    var publisherIndexController: PublisherIndexViewController?
    var seriesIndexController: SeriesIndexViewController?

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.autorecalculatesKeyViewLoop = false
    }
    
    func provide(context: ActionContext) {
        if let model = viewModel {
            context.info[ActionContext.modelKey] = model.managedObjectContext
            context.info[ActionContext.viewModelKey] = model
            context.info[ActionContext.windowKey] = self
            context.info[ActionContext.rootKey] = self
        }
    }
    
    func validateButtons() {
        if let view = window?.contentView {
            view.validateButtons()
        }
    }
    
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.action == #selector(delete(_:)) {
            return Application.sharedInstance.actionManager.validate(identifier: "DeleteItem", info: ActionInfo(sender: item)).enabled
        }
        return false
    }
    
    @IBAction func delete(_ sender: Any) {
        Application.sharedInstance.actionManager.perform(identifier: "DeleteItem", info: ActionInfo(sender: sender))
    }
}

extension CollectionWindowController: BookViewer {
    @objc func reveal(book: Book) {
        if let model = viewModel {
            bookIndexController?.select(books: [book])
            model.mode = .books
        }
    }
}

extension CollectionWindowController: PersonViewer {
    @objc func reveal(person: Person) {
        if let model = viewModel {
            personIndexController?.select(people: [person])
            model.mode = .people
        }
    }
}

extension CollectionWindowController: PublisherViewer {
    func reveal(publisher: Publisher) {
        if let model = viewModel {
            publisherIndexController?.select(publishers: [publisher])
            model.mode = .publishers
        }
    }
}

extension CollectionWindowController: SeriesViewer {
    func reveal(series: Series) {
        if let model = viewModel {
            seriesIndexController?.select(series: [series])
            model.mode = .series
        }
    }
}
