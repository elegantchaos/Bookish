// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/05/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class LateAutosavingWindowController: NSWindowController {
    var lateAutosaveName: String? {
        return nil
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        
        if let name = lateAutosaveName {
            // need to set the autosave name late - loading from a storyboard will overwrite it with the default value otherwise
            window?.setFrameUsingName(name)
            windowFrameAutosaveName = name
        }
    }
}
