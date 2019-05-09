// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 10/04/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel

class PersonCell: AnnotatedTableCellView {
    
    @IBOutlet weak var personButton: NSButton!
    var detailView: DetailController!

}

extension PersonCell: DetailTableCell {
    func setup(for row: DetailItem, of view: DetailController) {
        assert(row is PersonDetailItem)
        detailView = view
        if row.placeholder {
            personButton.stringValue = ""
            detailChannel.debug("setup as a placeholder")
        } else if let item = row as? PersonDetailItem, let person = item.person, let name = person.name {
            objectValue = person
            personButton.stringValue = name
        }
    }
    
    func keyView() -> NSView? {
        return personButton
    }
}

extension PersonCell: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.personKey] = objectValue as? Person
    }
}
