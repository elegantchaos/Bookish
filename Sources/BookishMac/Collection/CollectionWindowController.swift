// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel
import Logger

let validationChannel = Logger("Validation")

class CollectionWindowController: NSWindowController, ActionContextProvider {
    fileprivate var cvm: CollectionViewModel!
    
    var indexControllers: [String:Any] = [:]

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.autorecalculatesKeyViewLoop = false
    }
    
    func provide(context: ActionContext) {
        context.info[ActionContext.modelKey] = cvm.managedObjectContext
        context.info[ActionContext.viewModelKey] = cvm
        context.info[ActionContext.windowKey] = self
        context.info[ActionContext.rootKey] = self
    }
    
    func validateButtons() {
        if let view = window?.contentView {
            view.validateButtons()
        }
    }

    func reveal<EntityType: NSManagedObject>(_ object: EntityType, mode: CollectionViewModel.Mode) {
        cvm.mode = mode
        if let name = EntityType.entity().name {
            if let index = indexControllers[name] as? IndexController<EntityType> {
                index.select(items: [object])
            }
        }
    }
}

extension CollectionWindowController: WindowControllerWithViewModel {
    var viewModel: CollectionViewModel {
        return cvm
    }
    
    typealias ViewModel = CollectionViewModel

    func didConnect(to viewModel: CollectionViewModel) {
        self.cvm = viewModel
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
