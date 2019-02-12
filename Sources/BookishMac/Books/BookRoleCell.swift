// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 18/01/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import AppKit
import BookishModel


class BookRoleCell: NSTableCellView, BookDetailTableCell {
    @IBOutlet weak var rolePopup: ColoredPopUpButton!
    func setup(for detailView: BookDetailViewController, row: DetailItem) {
        assert(row is PersonDetailItem)
        if row.placeholder {
            rolePopup.selectItem(withTitle: "author")
        } else if let item = row as? PersonDetailItem, let relationship = item.relationship {
            objectValue = relationship
            
            if detailView.editing {
                let index = rolePopup.indexOfItem(withRepresentedObject: relationship.role)
                rolePopup.select(rolePopup.item(at: index))
            } else {
                textField?.stringValue = relationship.role?.name?.lowercased() ?? "<unknown>"
            }
        }
        
        textField?.isHidden = detailView.editing
        rolePopup.isHidden = !detailView.editing
        rolePopup.isEnabled = true
    }
    
    func keyView() -> NSView? {
        return nil
    }

}


extension BookRoleCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.relationshipKey] = objectValue as? Relationship
        context.info[PersonAction.roleKey] = rolePopup.selectedItem?.representedObject as? Role
    }
    
}
