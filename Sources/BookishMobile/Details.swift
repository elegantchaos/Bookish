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
    var sectionCount: Int { get }
    func sectionTitle(for section: Int) -> String
    func itemCount(for section: Int) -> Int
    func info(section: Int, row: Int) -> DetailDataSource.RowInfo // TODO: just take IndexPath?
    func filter(for selection: [ModelObject], editing: Bool)
}

extension DetailDataSource: DetailProvider {
    func info(section: Int, row: Int) -> DetailDataSource.RowInfo {
        return info(for: row)
    }
    
    func filter(for selection: [ModelObject], editing: Bool) {
        if let books = selection as? [Book] {
            filter(for: books, editing: editing)
        }
    }
    
    var sectionCount: Int {
        return 1
    }

    func sectionTitle(for section: Int) -> String {
        return ""
    }
    
    func itemCount(for section: Int) -> Int {
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
