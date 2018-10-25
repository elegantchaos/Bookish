// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel
import Actions


class BookDetailController: UIViewController {
    let source = DetailDataSource()
    lazy var placeholderImage = UIImage(named: "CoverPlaceholder")
    var bindings = [Any]()
    
    @IBOutlet weak var titleLabel: UITextField!
    @IBOutlet weak var subtitleLabel: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var detailView: UITableView!

    func configureView() {
        if let book = representedObject, titleLabel != nil {
            bindings.append(TextFieldBinding(for: titleLabel, to: book, path: "name"))
            bindings.append(TextFieldBinding(for: subtitleLabel, to: book, path: "subtitle"))
            if let imageData = book.image {
                imageView.image = UIImage(data: imageData)
            } else {
                imageView.image = placeholderImage
            }
            bindings.append(StringBinding(for: self, property: "title", to: book, path: "name"))
            if let roles = book.personRoles, let sorted = roles.sortedArray(using: application.viewModel.personRoleSorting) as? [PersonRole] {
                source.people = sorted
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }

    var representedObject: Book? {
        didSet {
            configureView()
        }
    }

}

// MARK: Table Support

extension BookDetailController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let book = representedObject else { fatalError("should have book set") }
        let info = source.info(for: indexPath.row)
        let identifier = info.identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as! BookDetailRow // if we fail here, it's a coding error as all possible view types should have been registered
        cell.setup(row: indexPath.row, book: book, source: source)
        return cell
    }
}
