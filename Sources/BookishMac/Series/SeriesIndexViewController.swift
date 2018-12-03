// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 03/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions


class SeriesIndexViewController: CollectionViewController {
    @objc weak var detailView: PersonDetailViewController!
    @IBOutlet weak var indexArray: NSArrayController!
    @IBOutlet weak var indexTable: NSTableView!
    
    @objc let sorting = [NSSortDescriptor(key: "name", ascending: true)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detailView = nearestSibling()
    }
    
    override func viewWillAppear() {
        if let window = parent?.view.window?.windowController as? CollectionWindowController {
            window.seriesIndexController = self
        }
        
        if (indexArray.content as? [Series])?.count == 0 {
            indexArray.fetch(self)
        }
        
        super.viewWillAppear()
    }
    
    func select(series: [Series]) {
        indexArray.setSelectedObjects(series)
        let index = indexTable.selectedRow
        if index != -1 {
            indexTable.scrollRowToVisible(index)
        }
    }
    
}

// MARK: Actions

extension SeriesIndexViewController: ActionContextProvider {
    func provideIndexInfo(context: ActionContext) {
//        context.info.addObserver(self)
    }
    
    func provide(context: ActionContext) {
        provideIndexInfo(context: context)
        detailView.provideDetailInfo(context: context)
    }
    
    func created(series: Series) {
        indexArray.setSelectedObjects([series])
    }
    
    func deleted(series: Series) {
    }
}
