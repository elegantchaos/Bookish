// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions
import Logger

let bookIndexChannel = Logger("BookIndex")

extension NSArrayController {
    func selectionSummary(singular: String, plural: String) -> String {
        let arranged = (arrangedObjects as! NSArray).count
        let selected = selectionIndexes.count
        let kind = arranged == 1 ? singular : plural
        if selected < 2 {
            return "\(arranged) \(kind)"
        } else {
            return "\(selected) of \(arranged) \(kind)"
        }
    }
}

class BookIndexViewController: CollectionViewController, BookLifecycleObserver {

    
    @objc weak var detailView: BookDetailViewController!
    @IBOutlet weak var indexArray: NSArrayController!
    @IBOutlet weak var indexTable: NSTableView!
    @IBOutlet weak var indexSearchField: NSSearchField!
    @IBOutlet weak var selectionLabel: NSTextField!
    var indexObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        detailView = nearestSibling()
        bookIndexChannel.debug("loaded")
    }
    
    override func viewWillAppear() {
        bookIndexChannel.debug("appearing")

        if let window = view.window?.windowController as? CollectionWindowController {
            window.bookIndexController = self
        }

        if (indexArray.content as? [Person])?.count == 0 {
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
        bookIndexChannel.debug("disappearing")
        
        indexObserver = nil
        super.viewWillDisappear()
    }
    
    func selectionChanged() {
        detailView.selectionChanged()
        
        selectionLabel.stringValue = indexArray.selectionSummary(singular: "book", plural: "books")
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
