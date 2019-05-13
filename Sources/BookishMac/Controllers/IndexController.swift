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

class IndexController: CollectionViewController {
    
    @IBOutlet var indexArray: NSArrayController!
    @IBOutlet weak var indexTable: NSTableView!
    @IBOutlet weak var indexSearchField: NSSearchField!
    @IBOutlet weak var selectionLabel: NSTextField!
    @IBOutlet weak var emptyIndexView: NSTextView!

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
    
    lazy var detailView: DetailController = nearestMatchingController()
    
    var observers: [NSKeyValueObservation] = []
    var fetchSessions: [FetchSession] = []
    var fetchState: FetchState = .unfetched
    
    override func windowDidLoad(_ window: NSWindowController, storyboard: NSStoryboard) {
        if let window = window as? CollectionWindowController {
            window.register(index: self, for: entityName)
        }

        super.windowDidLoad(window, storyboard: storyboard)
    }
    
    override func viewWillAppear() {
        indexChannel.debug("\(entityType) index appearing")
        
        updateVisibility()

        title = entityType.entityTitle
        indexArray.entityName = entityName
        indexArray.sortDescriptors = [NSSortDescriptor(key: "sortName", ascending: true)]
        observers.append(indexArray.observe(\NSArrayController.selection, changeHandler: { (index, change) in
            self.selectionChanged()
        }))
        
        fetchIfNecessary() {
            self.updateVisibility()
        }
        
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
        context.info[ActionContext.selectionKey] = indexArray?.selectedObjects
        context.info.addObserver(self)
    }
    
    func selectionChanged() {
        indexChannel.debug("\(entityType) selection changed")
        updateDetailView()
        updateVisibility()
    }
    
    func updateVisibility() {
        let entityCount = (indexArray.arrangedObjects as? NSArray)?.count ?? 0
        if entityCount == 0 {
            indexTable.isHidden = true
            indexSearchField.isHidden = true
            detailView.view.isHidden = true
            emptyIndexView.isHidden = false
            emptyIndexView.string = "\(self.entityName).empty".localized
            view.window?.makeFirstResponder(emptyIndexView)
        } else {
            indexTable.isHidden = false
            indexSearchField.isHidden = false
            emptyIndexView.isHidden = true
        }
    }
    
    func updateDetailView() {
        let selection = indexArray.selectedObjects as? [ModelObject] ?? []
        indexChannel.debug("showing detail for \(entityType): \(selection)")

        detailView.setup(for: self, type: entityType)
        
        let entityCount = (indexArray.arrangedObjects as? NSArray)?.count ?? 0
        let selectedCount = selection.count
        selectionLabel.stringValue = entityType.entityCount(entityCount, selected: selectedCount, prefix: "selected")
        selectionLabel.isHidden = selectedCount < 2
        indexSearchField.placeholderString = entityType.entityCount(entityCount, prefix: "search")
    }
    
    func select(items: [ModelObject], forEditing: Bool = false, forceUpdate: Bool = false) {
        fetchIfNecessary {
            DispatchQueue.main.async {
                self.indexArray.setSelectedObjects(items)
                let selection = self.indexTable.selectedRowIndexes
                self.indexTable.scrollRowToVisible(selection[selection.startIndex])
                self.indexTable.scrollRowToVisible(selection[selection.endIndex])
                if forEditing && !self.detailView.isEditing {
                    self.application.actionManager.perform(identifier: "ToggleEditing")
                } else if forceUpdate {
                    self.updateDetailView()
                }
            }
        }
    }
}

// MARK: Action Support

extension IndexController: ActionContextProvider {
    func provide(context: ActionContext) {
        addContextForIndex(context: context)
        detailView.addContextForDetail(context: context)
    }
    
}

extension IndexController: BookLifecycleObserver {
    func created(books: [Book]) {
        for book in books {
            application.windowController.reveal(book: book)
        }
    }
    
    func deleted(books: [Book]) {
    }
}

extension IndexController: PersonLifecycleObserver {
    func created(person: Person) {
        application.windowController.reveal(person: person)
    }
    
    func deleted(person: Person) {
    }
}

extension IndexController: PublisherLifecycleObserver {
    func created(publisher: Publisher) {
        application.windowController.reveal(publisher: publisher)
    }
    
    func deleted(publisher: Publisher) {
    }
}

extension IndexController: SeriesLifecycleObserver {
    func created(series: Series) {
        application.windowController.reveal(series: series)
    }
    
    func deleted(series: Series) {
    }
}

extension IndexController: RoleLifecycleObserver {
    func created(role: Role) {
        application.windowController.reveal(role: role)
    }
    
    func deleted(role: Role) {
    }
}
