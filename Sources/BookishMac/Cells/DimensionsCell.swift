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
        let binder = detailView.indexView.bindSelectionValue(forKey: property, to: field, transformer: "DoubleToString")
        detailView.binders.append(binder)
    }
    
    func keyView() -> NSView? {
        return textField
    }
}
