// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

class PublisherIndexViewController: CollectionViewController, IndexOwner {
    weak var detailView: PublisherDetailViewController!
    @IBOutlet weak var indexArray: NSArrayController!
    @IBOutlet weak var indexTable: NSTableView!
    
    @objc let sorting = [NSSortDescriptor(key: "name", ascending: true)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detailView = nearestSibling()
    }
    
    override func viewWillAppear() {
        if let window = parent?.view.window?.windowController as? CollectionWindowController {
            window.publisherIndexController = self
        }
        
        if (indexArray.content as? [Publisher])?.count == 0 {
            indexArray.fetch(self)
        }
        
        super.viewWillAppear()
    }
    
    func select(publishers: [Publisher]) {
        indexArray.setSelectedObjects(publishers)
        let index = indexTable.selectedRow
        if index != -1 {
            indexTable.scrollRowToVisible(index)
        }
    }
    
}

// MARK: Actions

extension PublisherIndexViewController: ActionContextProvider, PublisherConstructionObserver {
    func provideIndexInfo(context: ActionContext) {
        context.info.addObserver(self)
    }
    
    func provide(context: ActionContext) {
        provideIndexInfo(context: context)
        detailView.provideDetailInfo(context: context)
    }
    
    func created(publisher: Publisher) {
        indexArray.setSelectedObjects([publisher])
    }
    
    func deleted(publisher: Publisher) {
    }
}
