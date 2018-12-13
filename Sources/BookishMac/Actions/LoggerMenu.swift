// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Logger

class LoggerMenu: NSMenu, NSMenuDelegate {
    required init(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.delegate = self
    }
    
    func menuNeedsUpdate(_ menu: NSMenu) {
        removeAllItems()
        for logger in Logger.defaultManager.registeredChannels {
            let item = NSMenuItem(title: logger.name, action: #selector(toggleChannel(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = logger
            addItem(item)
        }
    }

    @IBAction func toggleChannel(_ sender: Any) {
        if let item = sender as? NSMenuItem, let channel = item.representedObject as? Logger {
            Logger.defaultManager.update(channels: [channel], state: !channel.enabled)
        }
    }

}
