// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class AnnotatedTableCellView: RepresentativeCellView, NSTextFieldDelegate {
    override func awakeFromNib() {
        super.awakeFromNib()
        hideButtons()
    }
    
    internal var annotationButtons: [NSButton] {
        get {
            return []
        }
    }

    private func hideButtons() {
        for button in annotationButtons {
            button.isHidden = true
        }
    }
    
    func showButtons() {
        for button in annotationButtons {
            button.isHidden = false
        }
    }
    
    func controlTextDidEndEditing(_ obj: Notification) {
        hideButtons()
    }
}
