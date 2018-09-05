// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class PersonTableCellView: NSTableCellView, NSTextFieldDelegate {
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var removeButton: NSButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        hideButtons()
    }
    
    private func hideButtons() {
        addButton.isHidden = true
        removeButton.isHidden = true
    }
    
    func showButtons() {
        addButton.isHidden = false
        removeButton.isHidden = false
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        hideButtons()
    }
}
