// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 15/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import Logger
import BookishModel

let indexChannel = Logger("Index")

/**
 Index view controller, parameterised by the kind of thing it's indexing.
 */

class GenericIndexController: CollectionViewController {
    
    @IBOutlet var indexArray: NSArrayController!
    @IBOutlet weak var indexTable: NSTableView!
    @IBOutlet weak var indexSearchField: NSSearchField!
    @IBOutlet weak var selectionLabel: NSTextField!

    typealias FetchCompletion = () -> Void

    enum FetchState {
        case unfetched
        case fetching
        case fetched
    }
    
    class FetchSession {
        var observer: NSKeyValueObservation? = nil
    }
    

    var entityType: ModelObject.Type = ModelObject.self
    var entityName: String = ""
    
    lazy var detailView: GenericDetailController = nearestMatchingController()
    
    var observers: [NSKeyValueObservation] = []
    var fetchSessions: [FetchSession] = []
    var fetchState: FetchState = .unfetched
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("blah")
    }
    
    override func windowDidLoad(_ window: NSWindowController, storyboard: NSStoryboard) {
        if let window = window as? CollectionWindowController {
            window.register(index: self, for: entityName)
        }
        super.windowDidLoad(window, storyboard: storyboard)
    }
    
    override func viewWillAppear() {
        indexChannel.debug("\(entityType) index appearing")
        
        title = entityType.entityTitle
        indexArray.entityName = entityName
        indexArray.sortDescriptors = [NSSortDescriptor(key: "sortName", ascending: true)]
        observers.append(indexArray.observe(\NSArrayController.selection, changeHandler: { (index, change) in
            self.selectionChanged()
        }))
        
        fetchIfNecessary()
        
        super.viewWillAppear()
    }
    
    override func viewWillDisappear() {
        indexChannel.debug("\(entityType) index disappearing")
        
        observers.removeAll()
        super.viewWillDisappear()
    }
    
    func setup(for entity: ModelObject.Type) {
        entityType = entity
        entityName = String(describing: entityType)
        indexChannel.debug("\(entityType) setup")
    }
    
    func fetchIfNecessary(then: FetchCompletion? = nil) {
        if fetchState == .fetched {
            then?()
        } else {
            indexChannel.debug("\(entityType) fetching data")
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
                then?()
            })
            fetchSessions.append(fetchSession)
        }
    }
    
    func addContextForIndex(context: ActionContext) {
        context.info.addObserver(self)
    }
    
    func selectionChanged() {
        indexChannel.debug("\(entityType) selection changed")
        if let selection = indexArray.selectedObjects as? [ModelObject] {
            detailView.setup(for: self, type: entityType)
            
            let entityCount = (indexArray.arrangedObjects as? NSArray)?.count ?? 0
            let selectedCount = selection.count
            selectionLabel.stringValue = entityType.entityCount(entityCount, selected: selectedCount, prefix: "selected")
            selectionLabel.isHidden = selectedCount < 2
            indexSearchField.placeholderString = entityType.entityCount(entityCount, prefix: "search")
        }
    }
    
    func select(items: [ModelObject]) {
        let index = indexArray
        fetchIfNecessary {
            var selection = items
            if selection.count == 0, let content = index?.arrangedObjects as? [ModelObject], let first = content.first {
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

extension GenericIndexController: ActionContextProvider {
    func provide(context: ActionContext) {
        addContextForIndex(context: context)
        detailView.addContextForDetail(context: context)
    }
    
}

extension GenericIndexController: BookLifecycleObserver {
    func created(books: [Book]) {
        self.select(items: books)
    }
    
    func deleted(books: [Book]) {
    }
}

extension GenericIndexController: PersonLifecycleObserver {
    func created(person: Person) {
        self.select(items: [person])
    }
    
    func deleted(person: Person) {
    }
}

extension GenericIndexController: PublisherLifecycleObserver {
    func created(publisher: Publisher) {
        self.select(items: [publisher])
    }
    
    func deleted(publisher: Publisher) {
    }
}

extension GenericIndexController: SeriesLifecycleObserver {
    func created(series: Series) {
        self.select(items: [series])
    }
    
    func deleted(series: Series) {
    }
}
