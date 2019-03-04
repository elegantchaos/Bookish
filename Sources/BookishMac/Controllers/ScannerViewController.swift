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
    @IBOutlet weak var barcodeView: NSTextField!
    @IBOutlet weak var candidatesTable: NSTableView!
    @IBOutlet weak var candidatesScrollView: NSScrollView!
    @IBOutlet weak var lookupSpinner: NSProgressIndicator!
    @IBOutlet weak var addButton: NSButton!

    var scanner: BarcodeScanner? = nil
    var detected: String = ""
    var lookup: LookupSession? = nil
    var candidates: [LookupCandidate] = []
    
    deinit {
        print("scanner view deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        barcodeView.stringValue = "candidate.lookup.scanning".localized
        candidatesScrollView.isHidden = true
        
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
                self.barcodeView.stringValue = key.localized(with: ["search": value])
            }
        }
    }
    
    
    func lookup(isbn: String) {
        lookup?.cancel()
        if let collection = application.viewModel?.collection {
            lookup = application.lookupManager.lookup(ean: isbn, collection: collection) { (session, state) in
                self.lookupUpdate(session: session, state: state)
            }
        }
    }
    
    func lookupUpdate(session: LookupSession, state: LookupSession.State) {
        switch state {
        case .starting:
            barcodeView.stringValue = "candidate.lookup.start".localized(with: ["search": session.search])
            lookupSpinner.startAnimation(self)
            lookupSpinner.isHidden = false
            candidates.removeAll()
            candidatesScrollView.isHidden = true
            candidatesTable.reloadData()
            addButton.isEnabled = false
            
        case .done:
            barcodeView.stringValue = "candidate.found".localized(count: candidates.count)
            lookupSpinner.stopAnimation(self)
            lookupSpinner.isHidden = true
            
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
        detected(barcode: "9781408832240")
        lookup(isbn: "9781408832240")
    }
    
    @IBAction func doAdd(_ sender: Any) {
        let state = application.viewModel
        if let candidate = candidates.first, let context = state?.managedObjectContext {
            let book = candidate.makeBook(in: context)
            application.windowController.reveal(book: book)
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
