// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel

class DateRow: BookDetailRow {
    override func setupContent(row: DetailItem, book: Book) {
        if let item = row as? SimpleDetailItem {
            detail.font = application.viewModel.detailFont
            detail.isEditable = item.source.isEditing
            let binding = TextViewBinding(for: detail, to: book, path: item.spec.binding, setIfNull: true)
            self.bindings.append(binding)
        }
    }
}
