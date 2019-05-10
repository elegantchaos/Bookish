// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions

class LinkField: NSTextField {
    var clickRecogniser: NSClickGestureRecognizer? = nil
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        if let oldRecogniser = clickRecogniser {
            removeGestureRecognizer(oldRecogniser)
        }
        let newRecogniser = NSClickGestureRecognizer(target: self, action: #selector(linkClicked(_:)))
        addGestureRecognizer(newRecogniser)
        clickRecogniser = newRecogniser

        self.textColor = .linkColor
        super.viewWillMove(toWindow: newWindow)
    }
    
    @IBAction func linkClicked(_ sender: Any) {
        application.actionManager.perform(identifier: "RevealItem", info: ActionInfo(sender: self))
    }
}
