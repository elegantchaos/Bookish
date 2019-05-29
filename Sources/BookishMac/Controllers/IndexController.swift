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
    
    @IBOutlet weak var indexTable: NSTableView!
    @IBOutlet weak var indexView: NSScrollView!
    @IBOutlet weak var indexSearchField: NSSearchField!
    @IBOutlet weak var selectionLabel: NSTextField!
    @IBOutlet weak var emptyIndexView: NSTextView!

    typealias Completion = () -> Void

    var entityType: ModelObject.Type = ModelObject.self
    var entityName: String = ""
    var selection = Selection<ModelObject>()
    var postInsertion: Completion? = nil
    
    private var fetcher: NSFetchedResultsController<ModelObject>? = nil
    
    func copySelectionValue(forKey key: String, to field: NSTextField, transformer: ValueTransformer? = nil, hideIfEmpty: Bool = false) {
        let value = selection.value(forKey: key)
        switch value {
        case .value(let value):
            if let transformer = transformer {
                field.objectValue = transformer.transformedValue(value)
            } else {
                field.objectValue = value
            }
            field.isHidden = (hideIfEmpty && field.stringValue.isEmpty)
        case .multipleValues:
            field.placeholderString = "Multiple values"
            field.objectValue = nil
        case .noSelection:
            break
        }
    }

    func bindSelectionValue(forKey key: String, to field: NSTextField, transformer: ValueTransformer? = nil, hideIfEmpty: Bool = false) -> Binder {
        let value = selection.value(forKey: key)
        field.placeholderString = "detail.\(key).placeholder".localized
        let binder = NSTextFieldBinder(target: field, property: key, source: value, actionManager: application.actionManager, transformer: transformer, hideIfEmpty: hideIfEmpty)
        return binder
    }

    func bindSelectionValue(forKey key: String, to field: NSTextField, transformer transformerName: String, hideIfEmpty: Bool = false) -> Binder {
        let transformer = ValueTransformer(forName: NSValueTransformerName(rawValue: transformerName))
        let value = selection.value(forKey: key)
        let binder = NSTextFieldBinder(target: field, property: key, source: value, actionManager: application.actionManager, transformer: transformer, hideIfEmpty: hideIfEmpty)
        return binder
    }


    
    func unbindSelectionValue(forKey key: String, from field: NSTextField) {
        // TODO: implement this
    }
    
    var objectCount: Int {
        return fetcher?.fetchedObjects?.count ?? 0
    }
    
    var objects: [ModelObject] {
        return fetcher?.fetchedObjects ?? []
    }
    
    lazy var detailView: DetailController = nearestMatchingController()
    
    var observers: [NSKeyValueObservation] = []
    
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
    }
    
    override func viewWillAppear() {
        indexChannel.debug("\(entityType) index appearing")
        self.updateVisibility()
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
        
        let context = cvm.managedObjectContext
        let request = NSFetchRequest<ModelObject>()
        request.entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[entityName]
        request.fetchBatchSize = 20
        request.sortDescriptors = cvm.entitySorting[entityName]
        let fetcher = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: entityName)
        fetcher.delegate = self
        do {
            try fetcher.performFetch()
            self.fetcher = fetcher
        } catch {
            print(error)
        }
        indexChannel.debug("\(entityType) setup with \(objectCount) objects.")
    }
    
    func completeOnMainThread(completion: Completion?) {
        if let completion = completion {
            DispatchQueue.main.async(execute: completion)
        }
    }
    
    func addContextForIndex(context: ActionContext) {
        context.info[ActionContext.selectionKey] = selection.objects
        context[FilterActions.filterableKey] = self
        context.info.addObserver(self)
    }
    
    func updateVisibility() {
        if objectCount == 0 {
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
        indexChannel.debug("showing detail for \(entityType): \(selection)")

        detailView.setup(for: self, type: entityType)
        
        let selectedCount = selection.count
        selectionLabel.stringValue = entityType.entityCount(objectCount, selected: selectedCount, prefix: "selected")
        selectionLabel.isHidden = selectedCount < 2
        indexSearchField.placeholderString = entityType.entityCount(objectCount, prefix: "search")
    }
    
    func select(items: [ModelObject], forceUpdate: Bool = false, completion: Completion? = nil) {
        indexChannel.log("Selecting \(items)")
        if items != selection.objects {
            selection.objects = items
            let indexes = selection.indexes(in: objects)
            indexTable.selectRowIndexes(indexes, byExtendingSelection: false)
            indexTable.scrollRowToVisible(indexes[indexes.startIndex])
            indexTable.scrollRowToVisible(indexes[indexes.endIndex])
            updateDetailView()
        } else if forceUpdate {
            updateDetailView()
        }
        
        DispatchQueue.main.async {
            completion?()
        }
    }
}

// MARK: Table Support

extension IndexController: NSTableViewDataSource, NSTableViewDelegate {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return objectCount
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let columnID = tableColumn?.identifier else { return nil }
        
        guard let view = tableView.makeView(withIdentifier: columnID, owner: self) else {
            return nil
        }
        
        if let cell = view as? IndexCell {
            let object = objects[row]
            detailCellChannel.log("made \(cell) for \(object)")
            cell.objectValue = object
        }
        
        return view
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        selection.set(from: indexTable.selectedRowIndexes, of: objects)
        indexChannel.debug("Selected \(selection.objects) (via table)")
        updateDetailView()
        updateVisibility()
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
            application.windowController.reveal(object: book, afterCreating: true)
        }
    }
    
    func deleted(books: [Book]) {
    }
}

extension IndexController: PersonLifecycleObserver {
    func created(person: Person) {
        application.windowController.reveal(object: person, afterCreating: true)
    }
    
    func deleted(person: Person) {
    }
}

extension IndexController: PublisherLifecycleObserver {
    func created(publisher: Publisher) {
        application.windowController.reveal(object: publisher, afterCreating: true)
    }
    
    func deleted(publisher: Publisher) {
    }
}

extension IndexController: SeriesLifecycleObserver {
    func created(series: Series) {
        application.windowController.reveal(object: series, afterCreating: true)
    }
    
    func deleted(series: Series) {
    }
}

extension IndexController: RoleLifecycleObserver {
    func created(role: Role) {
        application.windowController.reveal(object: role, afterCreating: true)
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

extension IndexController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            indexChannel.debug("\(entityType) inserted \(anObject)")
            if let path = newIndexPath {
                indexTable.insertRows(at: [path.item], withAnimation: .slideDown)
                //                tableView.selectRow(at: path, animated: true, scrollPosition: .middle)
            }
            updateVisibility()
            postInsertion?()
            postInsertion = nil

        case .delete:
            indexChannel.debug("\(entityType) deleted \(anObject)")
            if let path = indexPath {
                indexTable.removeRows(at: [path.item], withAnimation: .effectFade)
            }
            updateVisibility()

        case .update:
            
            if let indexPath = indexPath {
                let row = indexPath.item
                for column in 0..<indexTable.numberOfColumns {
                    if let cell = indexTable.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView {
                        //                        configureCell(cell: cell, row: row, column: column)
                    }
                }
            }
            
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                indexTable.removeRows(at: [indexPath.item], withAnimation: .effectFade)
                indexTable.insertRows(at: [newIndexPath.item], withAnimation: .effectFade)
            }
            
        default:
            break
        }
    }
}
