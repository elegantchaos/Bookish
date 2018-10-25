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
        // we really should be able to bind the array to the object context in IB, but
        // the document value is set relatively late, so it's safer to do it here
        indexArray.fetch(self)
        super.viewWillAppear()
    }
    
}

// MARK: Actions

extension PersonIndexViewController: ActionContextProvider, PersonConstructionObserver {
    func provideIndexInfo(context: ActionContext) {
        context.addObserver(self)
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
