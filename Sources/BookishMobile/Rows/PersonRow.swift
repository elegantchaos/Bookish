// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import Actions
import UIKit

class PersonRow: BookDetailRow {
    
    var person: Person?
    
    @IBOutlet var personButton: LinkButton!

    override func setupContent(row: DetailItem, object: ModelObject) {
        if let item = row as? PersonDetailItem {
            if item.placeholder {
                person = nil
            } else {
                person = item.person
            }
            
            setupPerson()
        }
    }
    
    func setupPerson() {
        let personName = person?.name ?? ""
        personButton.setTitle(personName, font: application.viewState.detailFont)
        personButton.linkedObject = person
    }
}

extension PersonRow: ActionContextProvider {
    func provide(context: ActionContext) {
        context.info[PersonAction.personKey] = person
    }
}
