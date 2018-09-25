// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

class PersonIndexViewController: CollectionViewController {
    @objc weak var detailView: PersonDetailViewController!
    @IBOutlet weak var indexArray: NSArrayController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        detailView = nearestSibling()
    }
    
    override func viewWillAppear() {
//        if let window = view.window?.windowController as? CollectionWindowController {
//            window.bookIndexController = self
//        }
        // we really should be able to bind the array to the object context in IB, but
        // the document value is set relatively late, so it's safer to do it here
        indexArray.fetch(self)
        super.viewWillAppear()
    }
    
}

// MARK: Actions

extension PersonIndexViewController: ActionContextProvider, PersonConstructionObserver {
    func provide(context: ActionContext) {
        if let selection = indexArray.selectedObjects as? [Person] {
            context.info[ActionContext.selectionKey] = selection
            context.append(key: PersonAction.observerKey, value: self)
        }
    }
    
    func created(person: Person) {
        indexArray.setSelectedObjects([person])
    }
    
    func deleted(person: Person) {
    }
}
