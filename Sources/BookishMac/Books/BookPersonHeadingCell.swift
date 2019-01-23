// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import AppKit
import BookishModel


class BookPersonHeadingCell: NSTableCellView, BookDetailTableCell {
    @IBOutlet weak var rolePopup: ColoredPopUpButton!
    func setup(for detailView: BookDetailViewController, row: DetailDataSource.RowInfo) {
        assert(row.category == .person)
        let source = detailView.source
        if row.placeholder {
            rolePopup.selectItem(withTitle: "author")
        } else {
            let relationship = source.relationship(for: row)
            objectValue = relationship
            
            if detailView.editing {
                let index = rolePopup.indexOfItem(withRepresentedObject: relationship.role)
                rolePopup.select(rolePopup.item(at: index))
//                for item in rolePopup.itemArray {
//                    if let itemRole = item.representedObject as? Role, itemRole == relationship.role {
//                        rolePopup.select(item)
//                        break
//                    }
//                }
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


extension BookPersonHeadingCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.relationshipKey] = objectValue as? Relationship
        context.info[PersonAction.roleKey] = rolePopup.selectedItem?.representedObject as? Role
    }
    
}
