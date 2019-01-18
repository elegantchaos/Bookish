// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

class ColoredPopUpButton: NSPopUpButton {
    var tColor: NSColor?
    
    @IBInspectable var titleColor: NSColor? {
        get { return tColor }
        set (value) {
            tColor = value
            setItemStyles()
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setItemStyles()
    }

    override func synchronizeTitleAndSelectedItem() {
        setItemStyles()
        super.synchronizeTitleAndSelectedItem()
    }

    override func addItem(withTitle title: String) {
        super.addItem(withTitle: title)
        setItemStyles()
    }

    override func addItems(withTitles itemTitles: [String]) {
        super.addItems(withTitles: itemTitles)
        setItemStyles()
    }

    override func insertItem(withTitle title: String, at index: Int) {
        super.insertItem(withTitle: title, at: index)
        setItemStyles()
    }

    public func setItemStyles() {
        if let color = tColor {
            for item in self.itemArray {
                item.attributedTitle = NSAttributedString(string: item.title, attributes: [NSAttributedString.Key.foregroundColor: color])
            }
        }
    }
}
