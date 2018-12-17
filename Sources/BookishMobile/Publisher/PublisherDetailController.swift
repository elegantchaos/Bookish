// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel
import Actions

class PublisherDetailController: DetailController<Publisher> {
    struct SortedRole {
        let role: Role
        let books: [Book]
    }
    
    lazy var placeholderImage = UIImage(named: "PublisherPlaceholder")
    var sortedRoles = [SortedRole]()
    
    @IBOutlet weak var nameLabel: UITextField!
    @IBOutlet weak var notesView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func configureView() {
        if let publisher = representedObject, nameLabel != nil {
            bindings.append(TextFieldBinding(for: nameLabel, to: publisher, path: "name"))
            bindings.append(TextViewBinding(for: notesView, to: publisher, path: "notes", setIfNull: true))
            if let imageData = publisher.image {
                imageView.image = UIImage(data: imageData)
            } else {
                imageView.image = placeholderImage
            }
            sortedRoles.removeAll()
//            for relationship in person.relationships?.sortedArray(using: application.viewModel.relationshipSorting) as! [Relationship] {
//                if let role = relationship.role,
//                    let books = relationship.books?.sortedArray(using: application.viewModel.bookIndexSorting) as? [Book] {
//                    sortedRoles.append(SortedRole(role: role, books: books))
//                }
//            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedRoles[section].books.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let role = sortedRoles[indexPath.section]
        let book = role.books[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "book") as! PersonBookRow // if we fail here, it's a coding error as all possible view types should have been registered
        cell.setup(row: indexPath.row, book: book, role:role.role)
        return cell
    }
}

