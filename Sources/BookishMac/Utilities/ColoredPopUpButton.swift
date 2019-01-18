// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

var ColoredPopupContext = 0

class ColoredPopUpButton: NSPopUpButton {
    var itemColor: NSColor?
    
    @IBInspectable var titleColor: NSColor? {
        get { return itemColor }
        set (value) {
            itemColor = value
            setItemStyles()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setItemStyles()
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
        if let color = itemColor {
            for item in self.itemArray {
                item.attributedTitle = NSAttributedString(string: item.title, attributes: [NSAttributedString.Key.foregroundColor: color])
            }
        }
    }
}
