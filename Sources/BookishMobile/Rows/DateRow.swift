// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel

class DateRow: BookDetailRow {
    override func setupContent(row: DetailItem, object: ModelObject) {
        if let item = row as? SimpleDetailItem {
            detail.font = application.viewState.detailFont
            detail.isEditable = item.source.isEditing
            if let date = object.value(forKey: item.spec.binding) as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .none
                detail.text = formatter.string(from: date)
            }
//            let binding = TextViewBinding(for: detail, to: object, path: item.spec.binding, setIfNull: true)
//            self.bindings.append(binding)
        }
    }
}
