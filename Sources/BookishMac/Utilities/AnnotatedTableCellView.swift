// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Logger

let reuseChannel = Logger("CellReuse")

class AnnotatedTableCellView: NSTableCellView, NSTextFieldDelegate {
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        hideButtons()
    }
    
    internal var annotationButtons: [NSButton] {
        get {
            return []
        }
    }

    public func hideButtons() {
        for button in annotationButtons {
            button.isHidden = true
        }
    }
    
    public func showButtons() {
        for button in annotationButtons {
            button.isHidden = false
        }
    }
    
    static public func updateSelection(tableView: NSTableView, row: Int) {
        let oldRow = tableView.selectedRow
        if oldRow != -1, let oldSelection = tableView.view(atColumn: 1, row: oldRow, makeIfNecessary: false) as? AnnotatedTableCellView {
            oldSelection.hideButtons()
        }
        
        if row != -1, let newSelection = tableView.view(atColumn: 1, row: row, makeIfNecessary: false) as? AnnotatedTableCellView {
            newSelection.showButtons()
        }
    }

    dynamic func controlTextDidEndEditing(_ obj: Notification) {
        hideButtons()
    }
    
    override func prepareForReuse() {
        reuseChannel.debug("reusing \(self)")
        hideButtons()
        objectValue = nil
        super.prepareForReuse()
    }
}
