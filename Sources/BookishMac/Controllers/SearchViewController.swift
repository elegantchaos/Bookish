// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Foundation
import BookishModel
import Logger
import CoreSpotlight

let searchChannel = Channel("com.elegantchaos.bookish.Search")

class SearchViewController: NSViewController {
    enum SearchMode {
        case basic
        case advanced
    }
    
    static let resultViewID = NSUserInterfaceItemIdentifier(rawValue: "result")
    
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var statusSpinner: NSProgressIndicator!
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet weak var searchButton: NSButton!
    @IBOutlet weak var candidatesTable: NSTableView!
    @IBOutlet weak var candidatesScrollView: NSScrollView!
    @IBOutlet weak var predicateEditor: NSPredicateEditor!
    
    var search: String = ""
    var lookup: LookupSession? = nil
    var fetcher: NSFetchedResultsController<ModelObject>? = nil
    var searcher: CSSearchQuery? = nil
    var results: [ModelObject] = []
    var mode: SearchMode = .basic
    var tableUpdater: FetchedResultsTableUpdater? = nil
    
    @objc var gotSearchText: Bool {
        return !searchField.stringValue.isEmpty
    }
    
    deinit {
        searchChannel.log("view disposed")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusLabel.stringValue = "search.initial".localized
        candidatesScrollView.isHidden = true
        predicateEditor.isHidden = mode == .basic
        
        if let context = application.viewModel?.managedObjectContext {
            
            let options = Int(NSComparisonPredicate.Options.caseInsensitive.rawValue + NSComparisonPredicate.Options.diacriticInsensitive.rawValue)
            //This is required for the Any, All and None option in the predicate editor
            let compound = NSPredicateEditorRowTemplate(compoundTypes: [
                NSNumber(value: NSCompoundPredicate.LogicalType.and.rawValue),
                NSNumber(value: NSCompoundPredicate.LogicalType.or.rawValue),
                NSNumber(value: NSCompoundPredicate.LogicalType.not.rawValue)
                ])
            
            let template = NSPredicateEditorRowTemplate(
                leftExpressions: [
                    NSExpression(forKeyPath: "any field")
                ],
                rightExpressionAttributeType: .stringAttributeType,
                modifier: .direct,
                operators: [
                    NSNumber(value: NSComparisonPredicate.Operator.equalTo.rawValue),
                    NSNumber(value: NSComparisonPredicate.Operator.contains.rawValue),
                    NSNumber(value: NSComparisonPredicate.Operator.beginsWith.rawValue),
                    NSNumber(value: NSComparisonPredicate.Operator.endsWith.rawValue),
                    NSNumber(value: NSComparisonPredicate.Operator.matches.rawValue),
                ],
                options: options
            )
            
            
            let description = ModelObject.entityDescription(for: Book.self, in: context)
            print(description.attributeKeys)
            let bookTemplates = NSPredicateEditorRowTemplate.templates(withAttributeKeyPaths: ["added", "asin", "classification", "format", "height", "imageURL", "importDate", "importRaw", "isbn", "length", "log", "modified", "name", "notes", "owner", "pages", "published", "read", "sortName", "source", "subtitle", "uuid", "weight", "width"], in:description)
            var templates: [NSPredicateEditorRowTemplate] = [compound, template]
            templates.append(contentsOf: bookTemplates)
            predicateEditor.rowTemplates = templates
            predicateEditor.addRow(self)            
        }
        
        
    }
    
    override func viewWillDisappear() {
        searcher?.cancel()
        searcher = nil
        fetcher = nil
        candidatesTable.delegate = nil
        candidatesTable.dataSource = nil
        lookup = nil
    }
    
    func startSearch() {
        switch mode {
        case .basic:
            startBasicSearch()

        case .advanced:
            startAdvancedSearch()
        }
    }
    
    func startBasicSearch() {
        searcher?.cancel()
        guard let model = application.viewModel else {
            searchChannel.fatal("missing model")
        }

        let context = model.managedObjectContext
        let string = searchField.stringValue
        var value = string
        if !value.contains("*") {
            value = "*\(value)*"
        }
        let query = "name == \"\(value)\"cd"
        let searcher = CSSearchQuery(queryString: query, attributes: [])
        searcher.foundItemsHandler = { items in
            var newResults: Set<ModelObject> = []
            for item in items {
                if let object = context.object(uri: item.uniqueIdentifier) as? ModelObject {
                    newResults.insert(object)
                }
            }
            DispatchQueue.main.async {
                self.candidatesScrollView.isHidden = false
                let count = self.results.count
                let additions = newResults.subtracting(self.results)
//                let indexes = IndexSet(integersIn: Range<IndexSet.Element>(uncheckedBounds: (count, count + additions.count - 1)))
                self.results.append(contentsOf: additions)
//                self.candidatesTable.insertRows(at: indexes, withAnimation: .slideDown)
                self.candidatesTable.reloadData()
            }
        }

        searchChannel.log("starting basic search for \(value)")
        results.removeAll()
        candidatesTable.reloadData()
        searcher.start()
        self.searcher = searcher
        self.search = string
    }
    
    func startAdvancedSearch() {
        guard let model = application.viewModel else {
            searchChannel.fatal("missing model")
        }
        
        let context = model.managedObjectContext
        let entityType = Book.self
        let entityName = String(describing: entityType)
        let cacheName = entityType.entityLabel
        
        fetcher = nil
        NSFetchedResultsController<ModelObject>.deleteCache(withName: cacheName)
        
        var predicate = predicateEditor.predicate
        if let format = predicate?.predicateFormat, format.contains("any field") {
            let newFormat = format.replacingOccurrences(of: "any field", with: "name")
            predicate = NSPredicate(format: newFormat)
        }
        
        let request = NSFetchRequest<ModelObject>()
        request.entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[entityName]
        request.fetchBatchSize = 20
        request.sortDescriptors = model.entitySorting[entityName]
        request.predicate = predicate
        
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: cacheName)
        controller.delegate = self
        fetcher = controller
        do {
            searchChannel.log("starting advanced search for \(predicate!)")
            try controller.performFetch()
            self.candidatesTable.reloadData()
            self.candidatesScrollView.isHidden = false
        } catch let err {
            print(err)
        }
    }
    
    @IBAction func doSearch(_ sender: Any) {
        startSearch()
    }
}

extension SearchViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        let count: Int
        if let sections = fetcher?.sections, sections.count > 0 {
            count = sections[0].numberOfObjects
            searchChannel.debug("got \(count) advanced results")
        } else {
            count = results.count
            searchChannel.debug("got \(count) simple results")
        }
        
        return count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let object: ModelObject
        
        if let fetcher = fetcher, let sections = fetcher.sections, sections.count > 0 {
            object = fetcher.object(at: IndexPath(item: row, section: 0))
        } else {
            object = results[row]
        }
        
        let view = tableView.makeView(withIdentifier: SearchViewController.resultViewID, owner: self) as! SearchResultCell
        view.setup(for: object)
        return view
    }
}

extension SearchViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        searchButton.isEnabled = !searchField.stringValue.isEmpty
    }
}

extension SearchViewController: NSFetchedResultsControllerDelegate {
    func makeFetcher(for search: String) -> NSFetchedResultsController<ModelObject> {
        
        guard let model = application.viewModel else {
            searchChannel.fatal("missing model")
        }
        
        let context = model.managedObjectContext
        let request = NSFetchRequest<ModelObject>()
        let entityType = Book.self
        let entityName = String(describing: entityType)
        request.entity = context.persistentStoreCoordinator?.managedObjectModel.entitiesByName[entityName]
        request.fetchBatchSize = 20
        request.sortDescriptors = model.entitySorting[entityName]
        request.predicate = NSPredicate(format: "name contains[cd] %@", search)
        let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: entityType.entityLabel)
        tableUpdater = FetchedResultsTableUpdater(table: candidatesTable)
        controller.delegate = tableUpdater
        return controller
    }
    
    
    
}
