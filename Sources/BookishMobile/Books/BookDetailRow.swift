// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel


class BookDetailRow: UITableViewCell, UITextViewDelegate, DetailRow {
    func setup(row: DetailDataSource.RowInfo, object: ModelObject) {
        if let book = object as? Book {
            setup(row: row, book: book)
        }
    }
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detail: UITextView!
    @IBOutlet weak var placeholder: UITextView!
    
    var bindings = [Any]()
    var source: DetailDataSource!
    var info: DetailDataSource.RowInfo!
    
    func setup(row: DetailDataSource.RowInfo, book: Book) {
        info = row
        source = row.source
        label.font = application.viewModel.labelFont
        label.text = source.heading(for: row) // TOOD: move method to info?
        setupContent(row: row, book: book)
    }
    
    func updatePlaceholder() {
        if let text = detail.text, !text.isEmpty {
            placeholder.isHidden = true
            placeholder.text = ""
        } else {
            placeholder.isHidden = false
            placeholder.text = "add \(label.text!)"
        }
    }
    
    func setupContent(row: DetailDataSource.RowInfo, book: Book) {
        assert(row.category == .detail)
        let rowInfo = source.details(for: row)
        detail.font = application.viewModel.detailFont
        detail.isEditable = source.editing
        let binding = TextViewBinding(for: detail, to: book, path: rowInfo.binding, setIfNull: true)
        bindings.append(binding)
        
        let observation = detail.observe(\UITextView.text) { (observed, value) in
            self.updatePlaceholder()
        }
        bindings.append(observation)
        updatePlaceholder()
//        if let text = book.value(forKey: rowInfo.binding) as? String, !text.isEmpty {
//            placeholder.isHidden = true
//            placeholder.text = ""
//        } else {
//            placeholder.isHidden = false
//            placeholder.text = "add \(label.text!)"
//        }
    }
    
    override func prepareForReuse() {
        bindings.removeAll()
    }
}
