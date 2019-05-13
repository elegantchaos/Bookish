// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Foundation
import BookishModel


class ScannerViewController: NSViewController, BarcodeScannerDelegate {
    
    static let candidateViewID = NSUserInterfaceItemIdentifier(rawValue: "candidate")
    
    @IBOutlet weak var imageView: NSView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var statusSpinner: NSProgressIndicator!
    @IBOutlet weak var searchField: NSTextField!
    @IBOutlet weak var searchButton: NSButton!
    @IBOutlet weak var candidatesTable: NSTableView!
    @IBOutlet weak var candidatesScrollView: NSScrollView!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var splitView: NSSplitView!
    
    var scanner: BarcodeScanner? = nil
    var detected: String = ""
    var lookup: LookupSession? = nil
    var candidates: [LookupCandidate] = []
    
    @objc var gotSearchText: Bool {
        return !searchField.stringValue.isEmpty
    }
    
    deinit {
        print("scanner view deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        statusLabel.stringValue = "candidate.lookup.initial".localized
        candidatesScrollView.isHidden = true

        // need to set the autosave name late - loading from a storyboard will overwrite it with the default value otherwise
        splitView.autosaveName = "scanner.splitview"
        
        if let scanner = BarcodeScanner(delegate: self) {
            self.scanner = scanner
            scanner.run()
        }
    }
    
    override func viewWillDisappear() {
        candidatesTable.delegate = nil
        candidatesTable.dataSource = nil
        scanner?.shutdown()
        scanner = nil
        lookup = nil
    }
    
    func attach(layer: CALayer) {
        layer.frame = view.bounds
        imageView.layer = layer
    }
    
    func detected(barcode value: String) {
        if detected != value {
            detected = value
            let valid = value.isISBN13
            if valid {
                lookup(isbn: value)
            }
            
            DispatchQueue.main.async {
                let key = valid ? "candidate.lookup.valid" : "candidate.lookup.invalid"
                self.searchField.stringValue = value
                self.statusLabel.stringValue = key.localized(with: ["search": value])
            }
        }
    }
    
    
    func lookup(isbn: String) {
        lookup?.cancel()
        if let context = application.viewModel?.collection.managedObjectContext {
            lookup = application.lookupManager.lookup(ean: isbn, context: context) { (session, state) in
                self.lookupUpdate(session: session, state: state)
            }
        }
    }
    
    func lookupUpdate(session: LookupSession, state: LookupSession.State) {
        switch state {
        case .starting:
            statusLabel.stringValue = "candidate.lookup.start".localized(with: ["search": session.search])
            statusSpinner.startAnimation(self)
            statusSpinner.isHidden = false
            candidates.removeAll()
            candidatesScrollView.isHidden = true
            candidatesTable.reloadData()
            addButton.isEnabled = false
            
        case .done:
            statusLabel.stringValue = "candidate.found".localized(count: candidates.count)
            statusSpinner.stopAnimation(self)
            statusSpinner.isHidden = true
            
        case .foundCandidate(let candidate):
            let rows = IndexSet(integer: candidates.count)
            candidates.append(candidate)
            candidatesScrollView.isHidden = false
            candidatesTable.insertRows(at: rows, withAnimation: .slideDown)
            if candidatesTable.selectedRow == -1 {
                candidatesTable.selectRowIndexes(rows, byExtendingSelection: false)
            }
            addButton.isEnabled = true
            
        default:
            break
        }
    }
    
    @IBAction func doTest(_ sender: Any) {
        searchField.stringValue = "9781408832240"
        doSearch(sender)
    }
    
    @IBAction func doSearch(_ sender: Any) {
        let code = searchField.stringValue
        if detected != code {
            detected(barcode: code)
            lookup(isbn: code)
        }
    }
    
    @IBAction func doAdd(_ sender: Any) {
        let state = application.viewModel
        let index = candidatesTable.selectedRow
        if (index >= 0) && (index < candidates.count) {
            let candidate = candidates[index]
            if let context = state?.managedObjectContext {
                let book = candidate.makeBook(in: context)
                application.windowController.reveal(book: book)
            }
        }
    }
    
    
}

extension ScannerViewController: NSTableViewDelegate, NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return candidates.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let view = tableView.makeView(withIdentifier: ScannerViewController.candidateViewID, owner: self) as! ScannerCandidateCell
        let candidate = candidates[row]
        view.setup(with: candidate)
        
        return view
    }
}

extension ScannerViewController: NSTextFieldDelegate {
    func controlTextDidChange(_ obj: Notification) {
        searchButton.isEnabled = !searchField.stringValue.isEmpty
    }
}
