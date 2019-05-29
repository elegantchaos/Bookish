// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

fileprivate var detailBindingContext: Int = 0

class DimensionsCell: AnnotatedTableCellView, DetailTableCell {
    @IBOutlet weak var widthField: NSTextField!
    @IBOutlet weak var heightField: NSTextField!
    @IBOutlet weak var lengthField: NSTextField!
    
    var detailView: DetailController!
    
    func setup(for row: DetailItem, of view: DetailController) {
        assert(row is SimpleDetailItem)
    
        detailView = view
        setupValue(field: widthField, property: "width")
        setupValue(field: heightField, property: "height")
        setupValue(field: lengthField, property: "length")
    }
    
    func setupValue(field: NSTextField, property: String) {
        detailView.indexView.bindSelectionValue(forKey: property, to: field)
    }
    
    func updateValue(field: NSTextField, property: String) {
        detailView.indexView.copySelectionValue(forKey: property, to: field)
    }
    
    func cleanupValue(field: NSTextField, property: String) {
        detailView.indexView.unbindSelectionValue(forKey: property, from: field)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &detailBindingContext {
            updateValue(field: widthField, property: "width")
            updateValue(field: heightField, property: "height")
            updateValue(field: lengthField, property: "length")
        }
    }
    
    func keyView() -> NSView? {
        return textField
    }
    
    override func prepareForReuse() {
        cleanupValue(field: widthField, property: "width")
        cleanupValue(field: heightField, property: "height")
        cleanupValue(field: lengthField, property: "length")
        super.prepareForReuse()
    }
}
