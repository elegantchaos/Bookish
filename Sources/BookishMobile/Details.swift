// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 06/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishModel
import UIKit

protocol DetailRow: UITableViewCell {
    func setup(row: DetailDataSource.RowInfo, object: ModelObject)
}

protocol DetailOwner {
    func getProvider() -> DetailProvider
}

protocol DetailProvider {
    var titleProperty: String? { get }
    var subtitleProperty: String? { get }
    var itemCount: Int { get }
    func info(for row: Int) -> DetailDataSource.RowInfo
    func filter(for selection: [ModelObject], editing: Bool)
}

extension DetailDataSource: DetailProvider {
    func filter(for selection: [ModelObject], editing: Bool) {
        if let books = selection as? [Book] {
            filter(for: books, editing: editing)
        }
    }
    
    var itemCount: Int {
        return rows
    }
    
    var titleProperty: String? {
        return "name"
    }
    
    var subtitleProperty: String? {
        return "subtitle"
    }
}

extension Book: DetailOwner {
    func getProvider() -> DetailProvider {
        return DetailDataSource()
    }
}
