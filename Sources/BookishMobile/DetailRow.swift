// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 08/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel

class DetailRow: UITableViewCell {
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var detail: UITextView!
    
    var binding: TextBinding<UITextView>?
    
    func setup(row: Int, book: Book, source: DetailDataSource) {
        assert(!source.info(for: row).isPerson)
        let rowInfo = source.details(for: row)
        label.text = rowInfo.label
        binding = TextBinding(for: detail, to: book, path: rowInfo.binding)
    }
}
