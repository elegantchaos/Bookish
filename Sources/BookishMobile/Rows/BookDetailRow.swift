// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel


class BookDetailRow: UITableViewCell, UITextViewDelegate, DetailRow {
    func setup(row: DetailItem, object: ModelObject) {
        if let book = object as? Book {
            setup(row: row, book: book)
        }
    }
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detail: UITextView!
    @IBOutlet weak var placeholder: UITextView!
    
    var bindings = [Any]()
    var info: DetailItem!
    
    func setup(row: DetailItem, book: Book) {
        info = row
        label.font = application.viewState.labelFont
        label.text = row.heading
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
    
    func setupContent(row: DetailItem, book: Book) {
        if let item = row as? SimpleDetailItem {
            detail.font = application.viewState.detailFont
            detail.isEditable = item.source.isEditing
            let binding = TextViewBinding(for: detail, to: book, path: item.spec.binding, setIfNull: true)
            bindings.append(binding)
            
            let observation = detail.observe(\UITextView.text) { (observed, value) in
                self.updatePlaceholder()
            }
            bindings.append(observation)
            updatePlaceholder()
        }
    }
    
    override func prepareForReuse() {
        bindings.removeAll()
    }
}
