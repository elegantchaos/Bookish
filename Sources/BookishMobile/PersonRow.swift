// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 22/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel

class PersonRow: DetailRow {
    override func setup(row: Int, book: Book, source: DetailDataSource) {
        assert(source.info(for: row).isPerson)
        let personRole = source.person(for: row)
        label.text = personRole.role?.name
        detail.text = personRole.person?.name
    }
}
