// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel

class BookDateRow: BookDetailRow {
    override func setupContent(row: DetailItem, book: Book) {
        assert(row is SimpleDetailItem)
        let rowInfo = source.details(for: row)
        detail.font = application.viewModel.detailFont
        detail.isEditable = source.editing
        let binding = TextViewBinding(for: detail, to: book, path: rowInfo.binding, setIfNull: true)
        self.bindings.append(binding)
    }
}
