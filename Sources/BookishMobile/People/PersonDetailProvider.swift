// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel


extension Person: DetailOwner {
    public func getProvider() -> DetailProvider {
        return PersonDetailProvider()
    }
}

class PersonDetailProvider: DetailProvider {
    struct SortedRole {
        let role: Role
        let books: [Book]
    }
    
    var sortedRoles = [SortedRole]()

    var titleProperty: String? {
        return "name"
    }
    
    var subtitleProperty: String? {
        return nil
    }
    
    var sectionCount: Int {
        return sortedRoles.count
    }

    func sectionTitle(for section: Int) -> String {
        return sortedRoles[section].role.name ?? ""
    }
    
    func itemCount(for section: Int) -> Int {
        return sortedRoles[section].books.count
    }

    func info(section: Int, row: Int) -> DetailItem {
        let info = SimpleDetailItem(kind: DetailSpec.textKind, absolute: row, index: row, placeholder: false, source: nil)
        return info
    }
    
    func filter(for selection: [ModelObject], editing: Bool) {
        let viewModel = Application.sharedInstance.viewModel
        if let person = selection.first as? Person, let relationships = person.relationships?.sortedArray(using: viewModel.relationshipSorting) as? [Relationship] {
            sortedRoles.removeAll()
            for relationship in relationships {
                if let role = relationship.role,
                    let books = relationship.books?.sortedArray(using: viewModel.bookIndexSorting) as? [Book] {
                    sortedRoles.append(SortedRole(role: role, books: books))
                }
            }
        }
    }
    
    
}

//
//    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        let role = sortedRoles[indexPath.section]
//        let book = role.books[indexPath.row]
//        let cell = tableView.dequeueReusableCell(withIdentifier: "book") as! PersonBookRow // if we fail here, it's a coding error as all possible view types should have been registered
//        cell.setup(row: indexPath.row, book: book, role:role.role)
//        return cell
//    }
//
