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
    @IBOutlet weak var indexView: NSScrollView!
    @IBOutlet weak var indexSearchField: NSSearchField!
    @IBOutlet weak var selectionLabel: NSTextField!
    @IBOutlet weak var emptyIndexView: NSTextView!

    typealias Completion = () -> Void

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
    var fetchCompletions: [Completion] = []
    var fetchState: FetchState = .unfetched
    var fetchObserver: NSKeyValueObservation? = nil
    
    override func windowDidLoad(_ window: NSWindowController, storyboard: NSStoryboard) {
        if let window = window as? CollectionWindowController {
            window.register(index: self, for: entityName)
        }

        super.windowDidLoad(window, storyboard: storyboard)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        indexView.isHidden = true
        emptyIndexView.isHidden = true
        if let url = Bundle.main.url(forResource: "Empty \(entityName)", withExtension: ".rtf"), let text = try? NSAttributedString(url: url, options: [:], documentAttributes: nil) {
            if let storage = emptyIndexView.textStorage {
                storage.replaceCharacters(in: NSRange(location: 0, length:storage.length), with: text)
            }
        }
        
        title = entityType.entityTitle
        indexArray.entityName = entityName
        indexArray.sortDescriptors = [NSSortDescriptor(key: "sortName", ascending: true)]
        
    }
    
    override func viewWillAppear() {
        indexChannel.debug("\(entityType) index appearing")

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
    
    func completeOnMainThread(completion: Completion?) {
        if let completion = completion {
            DispatchQueue.main.async(execute: completion)
        }
    }
    
    func fetchIfNecessary(then completion: Completion? = nil) {
        DispatchQueue.main.async {
            self.fetchOnMainThread(then: completion)
        }
    }
    
    func fetchOnMainThread(then completion: Completion? = nil) {
        switch self.fetchState {
        case .fetched:
            assert(fetchCompletions.count == 0)
            completion?()
            
        case .fetching:
            assert(fetchCompletions.count > 0)
            if let completion = completion {
                fetchCompletions.append(completion)
            }
            
        case .unfetched:
            indexChannel.debug("\(entityType) fetching data")
            assert(fetchCompletions.count == 0)
            if let completion = completion {
                fetchCompletions.append(completion)
            }
            fetchObserver = indexArray.observe(\NSArrayController.content) { (value, change) in
                DispatchQueue.main.async {
                    self.fetchState = .fetched
                    for completion in self.fetchCompletions {
                        completion()
                    }
                    self.fetchCompletions.removeAll()
                }
            }
            fetchState = .fetching
            indexArray.fetch(self)
            
        }
    }
    
    func addContextForIndex(context: ActionContext) {
        context.info[ActionContext.selectionKey] = indexArray?.selectedObjects
        context[FilterActions.filterableKey] = self
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
            indexView.isHidden = true
            indexSearchField.isHidden = true
            emptyIndexView.isHidden = false
            
            detailView.setupAsEmpty()
            view.window?.makeFirstResponder(emptyIndexView)
        } else {
            indexView.isHidden = false
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
    
    func select(items: [ModelObject], forEditing: Bool = false, forceUpdate: Bool = false, completion: Completion? = nil) {
        fetchIfNecessary {
            indexChannel.log("Selecting \(items)")
            self.indexArray.setSelectedObjects(items)
            let selection = self.indexTable.selectedRowIndexes
            self.indexTable.scrollRowToVisible(selection[selection.startIndex])
            self.indexTable.scrollRowToVisible(selection[selection.endIndex])
            if forEditing && !self.detailView.isEditing {
                self.application.actionManager.perform(identifier: "ToggleEditing")
            } else if forceUpdate {
                self.updateDetailView()
            }
            DispatchQueue.main.async {
                completion?()
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
            application.windowController.reveal(object: book, forEditing: true)
        }
    }
    
    func deleted(books: [Book]) {
    }
}

extension IndexController: PersonLifecycleObserver {
    func created(person: Person) {
        application.windowController.reveal(object: person, forEditing: true)
    }
    
    func deleted(person: Person) {
    }
}

extension IndexController: PublisherLifecycleObserver {
    func created(publisher: Publisher) {
        application.windowController.reveal(object: publisher, forEditing: true)
    }
    
    func deleted(publisher: Publisher) {
    }
}

extension IndexController: SeriesLifecycleObserver {
    func created(series: Series) {
        application.windowController.reveal(object: series, forEditing: true)
    }
    
    func deleted(series: Series) {
    }
}

extension IndexController: RoleLifecycleObserver {
    func created(role: Role) {
        application.windowController.reveal(object: role, forEditing: true)
    }
    
    func deleted(role: Role) {
    }
}

extension IndexController: NSTextViewDelegate {
    func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
        if let url = link as? URL, url.scheme == "action", let action = url.host {
            application.actionManager.perform(identifier: action)
            return true
        }
        
        return false
    }
}

extension IndexController: FilterableView {
    func clearFilter() {
        indexSearchField.stringValue = ""
    }
}
