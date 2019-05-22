// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions

class ConfirmationAction: Action {
    static let messageKey = "message"
    static let textKey = "text"
    static let actionKey = "action"
    
    override func perform(context: ActionContext) {
        
        if let wc = context[ActionContext.windowKey] as? NSWindowController, let window = wc.window {
            let alert = NSAlert()
            alert.messageText = context[ConfirmationAction.messageKey] as? String ?? "message"
            alert.informativeText = context[ConfirmationAction.textKey] as? String ?? "informative"
            alert.addButton(withTitle: "OK")
            
            alert.beginSheetModal(for: window) { (response) in
                
            }
        }
    }
}
