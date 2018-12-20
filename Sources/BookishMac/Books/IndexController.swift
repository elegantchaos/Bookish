// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import Logger

let indexChannel = Logger("Index")


class IndexControllerBase: CollectionViewController {
    @IBOutlet weak var indexArray: NSArrayController!
    @IBOutlet weak var indexTable: NSTableView!
    @IBOutlet weak var indexSearchField: NSSearchField!
    @IBOutlet weak var selectionLabel: NSTextField!
    var indexObserver: NSKeyValueObservation?
    weak var detailView: DetailControllerBase!
}

extension IndexControllerBase: ActionContextProvider, ActionObserver {
    func provideForIndex(context: ActionContext) {
        context.info.addObserver(self)
    }
    
    func provide(context: ActionContext) {
        provideForIndex(context: context)
        detailView.provideForDetail(context: context)
    }
}
class IndexController<EntityType>: IndexControllerBase {
    let entityName = "\(EntityType.self)"
    
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
    
    func selectionChanged() {
        detailView.selectionChanged()
        
        selectionLabel.stringValue = indexArray.selectionSummary(singular: "book", plural: "books")
    }
    
    func select(items: [EntityType]) {
        indexArray.setSelectedObjects(items)
        let index = indexTable.selectedRow
        if index != -1 {
            indexTable.scrollRowToVisible(index)
        }
    }
}


