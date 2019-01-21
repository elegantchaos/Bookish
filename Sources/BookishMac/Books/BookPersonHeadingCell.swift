// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import AppKit


class BookPersonHeadingCell: NSTableCellView, BookDetailTableCell {
    @IBOutlet weak var rolePopup: ColoredPopUpButton!
    func setup(for detailView: BookDetailViewController, row: DetailDataSource.RowInfo) {
        assert(row.category == .person)
        let source = detailView.source
        if row.placeholder {
            rolePopup.selectItem(withTitle: "author")
        } else {
            let relationship = source.person(for: row)
            objectValue = relationship
            
            if detailView.editing {
                for item in rolePopup.itemArray {
                    if let itemRole = item.representedObject as? Role, itemRole == relationship.role {
                        rolePopup.select(item)
                        break
                    }
                }
            } else {
                textField?.stringValue = relationship.role?.name?.lowercased() ?? "<unknown>"
            }
        }
        
        textField?.isHidden = detailView.editing
        rolePopup.isHidden = !detailView.editing
    }
    
    func keyView() -> NSView? {
        return nil
    }
    
}
