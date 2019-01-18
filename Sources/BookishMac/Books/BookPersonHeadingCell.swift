// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import AppKit


class BookPersonHeadingCell: NSTableCellView, BookDetailTableCell {
    @IBOutlet weak var rolePopup: ColoredPopUpButton!
    func setup(for detailView: BookDetailViewController, row: DetailDataSource.RowInfo) {
//        rolePopup.setItemStyles()

        assert(row.category == .person)
        let source = detailView.source
        if row.placeholder {
            rolePopup.selectItem(withTitle: "Author")
        } else {
            let relationship = source.person(for: row)
            objectValue = relationship
            for item in rolePopup.itemArray {
                if let itemRole = item.representedObject as? Role, itemRole == relationship.role {
                    rolePopup.select(item)
                    break
                }
            }
//            if let role = relationship.role {
//            }
        }
    }
    
    func keyView() -> NSView? {
        return nil
    }
    
}
