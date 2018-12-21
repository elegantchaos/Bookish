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
    enum FetchState {
        case unfetched
        case fetching
        case fetched
    }
    
    class FetchSession {
        var observer: NSKeyValueObservation? = nil
    }
    
    let entityName = "\(EntityType.self)"
    weak var detailView: DetailController<EntityType>!
    var observers: [NSKeyValueObservation] = []
    var fetchSessions: [FetchSession] = []
    var fetchState: FetchState = .unfetched
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        indexChannel.debug(" \(entityName) index loaded")
    }
    
    override func windowDidLoad(_ window: CollectionWindowController) {
        indexChannel.debug(" \(entityName) index window loaded")
        if let dv: DetailController<EntityType> = nearestSibling() {
            detailView = dv
        }
        window.indexControllers[entityName] = self
    }
    
    
    override func viewWillAppear() {
        indexChannel.debug(" \(entityName) index appearing")
        
        if let indexArray = indexArray {
            observers.append(indexArray.observe(\NSArrayController.selection, changeHandler: { (index, change) in
                self.selectionChanged()
            }))
            
            fetchIfNecessary {
            }
        }
        
        super.viewWillAppear()
    }
    
    override func viewWillDisappear() {
        indexChannel.debug("\(entityName) index disappearing")

        observers.removeAll()
        super.viewWillDisappear()
    }
    
    func fetchIfNecessary(then: @escaping () -> Void) {
        if fetchState == .fetched {
            then()
        } else {
            indexChannel.debug("\(entityName) fetching data")
            if fetchState == .unfetched {
                indexArray.fetch(self)
                fetchState = .fetching
            }
            let fetchSession = FetchSession()
            fetchSession.observer = indexArray.observe(\NSArrayController.content, changeHandler: { (value, change) in
                self.fetchState = .fetched
                indexChannel.debug("\(self.entityName) changed")
                if let index = self.fetchSessions.firstIndex(where: { return ($0 === fetchSession)}) {
                    self.fetchSessions.remove(at: index)
                }
                then()
            })
            fetchSessions.append(fetchSession)
        }
    }
    
    func provideForIndex(context: ActionContext) {
        context.info.addObserver(self)
    }

    func selectionChanged() {
        indexChannel.debug("\(entityName) selection changed")
        detailView.selectionChanged()
        selectionLabel.stringValue = indexArray.selectionSummary(entity: entityName)
    }
    
    func select(items: [EntityType]) {
        let index = indexArray
        fetchIfNecessary {
            var selection = items
            if selection.count == 0, let content = index?.arrangedObjects as? [EntityType], let first = content.first {
                selection = [first]
            }
            indexChannel.debug("\(self.entityName) selecting \(selection)")
            self.indexArray.setSelectedObjects(selection)
            let index = self.indexTable.selectedRow
            if index != -1 {
                self.indexTable.scrollRowToVisible(index)
            }
        }
        DispatchQueue.main.async {
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
