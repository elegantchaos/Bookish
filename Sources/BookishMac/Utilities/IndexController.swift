// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import Logger

let indexChannel = Logger("Index")

/**
 Base class containing the things we want to be able to bind to,
 since they can't live in a Swift generic class.
 */

class IndexControllerBindings: CollectionViewController {
    @IBOutlet weak var indexArray: NSArrayController!
    @IBOutlet weak var indexTable: NSTableView!
    @IBOutlet weak var indexSearchField: NSSearchField!
    @IBOutlet weak var selectionLabel: NSTextField!
}

/**
 Index view controller, parameterised by the kind of thing it's indexing.
 */

class IndexController<EntityType>: IndexControllerBindings, ActionObserver {
    let entityName = "\(EntityType.self)"
    weak var detailView: DetailController<EntityType>!
    var indexObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let dv: DetailController<EntityType> = nearestSibling() {
            detailView = dv
        }
        indexChannel.debug(" \(entityName) index loaded")
    }
    
    override func viewWillAppear() {
        indexChannel.debug(" \(entityName) index appearing")
        
        if let window = view.window?.windowController as? CollectionWindowController {
            window.indexControllers[entityName] = self
        }
        
        if (indexArray.content as? [EntityType])?.count == 0 {
            indexArray.fetch(self)
        }
        
        if let indexArray = indexArray {
            indexObserver = indexArray.observe(\NSArrayController.selection, changeHandler: { (index, change) in
                self.selectionChanged()
            })
            selectionChanged()
        }
        
        super.viewWillAppear()
    }
    
    override func viewWillDisappear() {
        indexChannel.debug(" \(entityName) index disappearing")
        
        indexObserver = nil
        super.viewWillDisappear()
    }
    
    func provideForIndex(context: ActionContext) {
        context.info.addObserver(self)
    }

    func selectionChanged() {
        detailView.selectionChanged()
        selectionLabel.stringValue = indexArray.selectionSummary(entity: entityName)
    }
    
    func select(items: [EntityType]) {
        indexArray.setSelectedObjects(items)
        let index = indexTable.selectedRow
        if index != -1 {
            indexTable.scrollRowToVisible(index)
        }
    }
}

// MARK: Action Support

extension IndexController: ActionContextProvider {
    func provide(context: ActionContext) {
        provideForIndex(context: context)
        detailView.provideForDetail(context: context)
    }

}
