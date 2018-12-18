// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel

class BookDetailRow: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detail: UITextView!
    
    var binding: TextViewBinding?
    
    func setup(row: DetailDataSource.RowInfo, book: Book, source: DetailDataSource) {
        assert(row.category == .detail)
        let rowInfo = source.details(for: row)
        label.text = rowInfo.label
        binding = TextViewBinding(for: detail, to: book, path: rowInfo.binding, setIfNull: true)
    }
}
