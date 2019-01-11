// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel
import Logger

let validationChannel = Logger("Validation")

class CollectionWindowController: NSWindowController, WindowControllerWithViewModel, ActionContextProvider {
    var viewModel: CollectionViewModel?
    typealias ViewModel = CollectionViewModel
    
    var indexControllers: [String:Any] = [:]

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

    func reveal<EntityType: NSManagedObject>(_ object: EntityType, mode: CollectionViewModel.Mode) {
        if let model = viewModel {
            model.mode = mode
            if let name = EntityType.entity().name {
                if let index = indexControllers[name] as? IndexController<EntityType> {
                    index.select(items: [object])
                }
            }
        }
    }

}

extension CollectionWindowController: BookViewer {
    @objc func reveal(book: Book) {
        reveal(book, mode: .books)
    }
}

extension CollectionWindowController: PersonViewer {
    @objc func reveal(person: Person) {
        reveal(person, mode: .people)
    }
}

extension CollectionWindowController: PublisherViewer {
    func reveal(publisher: Publisher) {
        reveal(publisher, mode: .publishers)
    }
}

extension CollectionWindowController: SeriesViewer {
    func reveal(series: Series) {
        reveal(series, mode: .series)
    }
}
