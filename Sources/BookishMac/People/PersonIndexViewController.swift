// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

class PersonIndexViewController: CollectionViewController, IndexOwner {
    weak var detailView: PersonDetailViewController!
    @IBOutlet weak var indexArray: NSArrayController!
    @IBOutlet weak var indexTable: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        detailView = nearestSibling()
    }
    
    override func viewWillAppear() {
        if let window = parent?.view.window?.windowController as? CollectionWindowController {
            window.personIndexController = self
        }

        if (indexArray.content as? [Person])?.count == 0 {
            // we really should be able to bind the array to the object context in IB, but
            // the document value is set relatively late, so it's safer to do it here
            indexArray.fetch(self)
        }
        super.viewWillAppear()
    }
    
    func select(people: [Person]) {
        indexArray.setSelectedObjects(people)
        let index = indexTable.selectedRow
        if index != -1 {
            indexTable.scrollRowToVisible(index)
        }
    }

}

// MARK: Actions

extension PersonIndexViewController: ActionContextProvider, PersonLifecycleObserver {
    func provideIndexInfo(context: ActionContext) {
        context.info.addObserver(self)
    }

    func provide(context: ActionContext) {
        provideIndexInfo(context: context)
        detailView.provideDetailInfo(context: context)
    }
    
    func created(person: Person) {
        indexArray.setSelectedObjects([person])
    }
    
    func deleted(person: Person) {
    }
}
