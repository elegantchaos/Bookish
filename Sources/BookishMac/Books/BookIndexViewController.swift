// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

class BookIndexViewController: CollectionViewController, BookLifecycleObserver {

    
    @objc weak var detailView: BookDetailViewController!
    @IBOutlet weak var indexArray: NSArrayController!
    @IBOutlet weak var indexTable: NSTableView!
    @IBOutlet weak var indexSearchField: NSSearchField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detailView = nearestSibling()
//        (indexSearchField.cell as! NSSearchFieldCell).backgroundColor = NSColor.red
    }
    
    override func viewWillAppear() {
        if let window = view.window?.windowController as? CollectionWindowController {
            window.bookIndexController = self
        }

        if (indexArray.content as? [Person])?.count == 0 {
            // we really should be able to bind the array to the object context in IB, but
            // the document value is set relatively late, so it's safer to do it here
            indexArray.fetch(self)
        }
        
        super.viewWillAppear()
    }
    
    func select(books: [Book]) {
        indexArray.setSelectedObjects(books)
        let index = indexTable.selectedRow
        if index != -1 {
            indexTable.scrollRowToVisible(index)
        }    }
}

extension BookIndexViewController: ActionContextProvider {
    func provideForIndex(context: ActionContext) {
        context.info.addObserver(self)
    }
    
    func provide(context: ActionContext) {
        provideForIndex(context: context)
        detailView.provideForDetail(context: context)
    }

    func created(books: [Book]) {
        DispatchQueue.main.async {
            self.select(books: books)
        }
    }
    
    func deleted(books: [Book]) {
        
    }
}
