// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/11/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel
import Actions

fileprivate var detailBindingContext: Int = 0

class BookDimensionsCell: AnnotatedTableCellView, BookDetailTableCell {
    var index: NSArrayController?
    
    @IBOutlet weak var widthField: NSTextField!
    @IBOutlet weak var heightField: NSTextField!
    @IBOutlet weak var lengthField: NSTextField!
    
    func setup(for view: BookDetailViewController, row: DetailDataSource.RowInfo) {
        assert(row.category == .detail)
        
        index = view.index
        setupValue(field: widthField, property: "width")
        setupValue(field: heightField, property: "height")
        setupValue(field: lengthField, property: "length")
    }
    
    func setupValue(field: NSTextField, property: String) {
        if let index = index {
            index.addObserver(self, forKeyPath: "selection.\(property)", options: [.initial], context: &detailBindingContext)
        }
    }
    
    func updateValue(field: NSTextField, property: String) {
        if let selection = index?.selection as? NSObject {
            let selection = selection.value(forKey: property) as? NSObject
            if selection === NSMultipleValuesMarker {
                field.placeholderString = "Multiple Values"
            } else {
                field.objectValue = selection
            }
        }
    }
    
    func cleanupValue(field: NSTextField, property: String) {
        index?.removeObserver(self, forKeyPath: "selection.\(property)", context: &detailBindingContext)
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
