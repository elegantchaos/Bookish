// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Foundation
import BookishModel
import Logger

let searchChannel = Channel("com.elegantchaos.bookish.Search")

class SearchViewController: NSViewController {
    
    static let candidateViewID = NSUserInterfaceItemIdentifier(rawValue: "candidate")
    
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
    var results: [ModelObject] = []
    
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
        candidatesTable.delegate = nil
        candidatesTable.dataSource = nil
        lookup = nil
    }
    
    func search(for string: String) {
        search = string
        
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
            try controller.performFetch()
            self.candidatesTable.reloadData()
            self.candidatesScrollView.isHidden = false
        } catch let err {
            print(err)
        }
    }
    
    
    @IBAction func doSearch(_ sender: Any) {
        let string = searchField.stringValue
//        if search != string {
            search(for: string)
//        }
    }
}

extension SearchViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        guard let sections = fetcher?.sections, sections.count > 0 else {
            return 0
        }
        
        return sections[0].numberOfObjects
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let sections = fetcher?.sections, sections.count > 0 else {
            return nil
        }
        
        let view = tableView.makeView(withIdentifier: SearchViewController.candidateViewID, owner: self) as! ScannerCandidateCell
        let item = fetcher?.object(at: IndexPath(item: row, section: 0))
        if let name = item?.value(forKey: "name") as? String {
            view.titleField.stringValue = name
        }
        //        view.setup(with: candidate)
        
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
        controller.delegate = self
        return controller
    }
    
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        candidatesTable.beginUpdates()
    }
    //
    //    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    //        switch type {
    //        case .insert:
    //            candidatesTable.insertSections(IndexSet(integer: sectionIndex), with: .fade)
    //        case .delete:
    //            candidatesTable.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
    //        default:
    //            return
    //        }
    //    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let path = newIndexPath {
                candidatesTable.insertRows(at: [path.item], withAnimation: .slideDown)
                //                tableView.selectRow(at: path, animated: true, scrollPosition: .middle)
            }
            
        case .delete:
            if let path = indexPath {
                candidatesTable.removeRows(at: [path.item], withAnimation: .effectFade)
            }
            
        case .update:
            
            if let indexPath = indexPath {
                let row = indexPath.item
                for column in 0..<candidatesTable.numberOfColumns {
                    if let cell = candidatesTable.view(atColumn: column, row: row, makeIfNecessary: true) as? NSTableCellView {
                        //                        configureCell(cell: cell, row: row, column: column)
                    }
                }
            }
            
        case .move:
            if let indexPath = indexPath, let newIndexPath = newIndexPath {
                candidatesTable.removeRows(at: [indexPath.item], withAnimation: .effectFade)
                candidatesTable.insertRows(at: [newIndexPath.item], withAnimation: .effectFade)
            }
            
        default:
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        candidatesTable.endUpdates()
    }
    
}
