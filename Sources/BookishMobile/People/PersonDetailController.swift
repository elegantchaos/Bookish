// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel
import Actions

class PersonDetailController: DetailController<Person> {
    struct SortedRole {
        let role: Role
        let books: [Book]
    }
    
    lazy var placeholderImage = UIImage(named: "PersonPlaceholder")
    var sortedRoles = [SortedRole]()
    
    @IBOutlet weak var nameLabel: UITextField!
    @IBOutlet weak var notesView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func configureView() {
        if let person = representedObject, nameLabel != nil {
            bindings.append(TextFieldBinding(for: nameLabel, to: person, path: "name"))
            bindings.append(TextViewBinding(for: notesView, to: person, path: "notes", setIfNull: true))
            if let imageData = person.image {
                imageView.image = UIImage(data: imageData)
            } else {
                imageView.image = placeholderImage
            }
            sortedRoles.removeAll()
            for relationship in person.relationships?.sortedArray(using: application.viewModel.relationshipSorting) as! [Relationship] {
                if let role = relationship.role,
                    let books = relationship.books?.sortedArray(using: application.viewModel.bookIndexSorting) as? [Book] {
                    sortedRoles.append(SortedRole(role: role, books: books))
                }
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        let sections = sortedRoles.count
        print(sections)
        return sections
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedRoles[section].books.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let title = sortedRoles[section].role.name
        print(title)
        return title
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let role = sortedRoles[indexPath.section]
        let book = role.books[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "book") as! PersonBookRow // if we fail here, it's a coding error as all possible view types should have been registered
        cell.setup(row: indexPath.row, book: book, role:role.role)
        return cell
    }
}

