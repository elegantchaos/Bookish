// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 05/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class AnnotatedTextField: NSTextField {
    
    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            if let cellView = delegate as? AnnotatedTableCellView {
                cellView.showButtons()
            }
        }
        return result
    }

}
