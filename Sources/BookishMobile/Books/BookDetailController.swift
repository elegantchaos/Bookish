// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel
import Actions
import Logger

let bookDetailChannel = Logger("BookDetails")

class BookDetailController: DetailController<Book> {
    let source = DetailDataSource()
    lazy var placeholderImage = UIImage(named: "CoverPlaceholder")
    
    @IBOutlet weak var titleLabel: UITextField!
    @IBOutlet weak var subtitleLabel: UITextField!
    @IBOutlet weak var imageView: UIImageView!

    override func configureView() {
        if let book = representedObject, titleLabel != nil {
            bindings.append(TextFieldBinding(for: titleLabel, to: book, path: "name"))
            bindings.append(TextFieldBinding(for: subtitleLabel, to: book, path: "subtitle"))
            if let imageData = book.image {
                imageView.image = UIImage(data: imageData)
            } else {
                imageView.image = placeholderImage
            }
            bindings.append(StringBinding(for: self, property: "title", to: book, path: "name"))
            source.filter(for: [book], editing: isEditing)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.rows
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let book = representedObject else { fatalError("should have book set") }
        let info = source.info(for: indexPath.row, editing: isEditing)
        let identifier = info.kind.rawValue
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? BookDetailRow else {
            bookDetailChannel.log("Unregistered cell type \(identifier).")
            return UITableViewCell(style: .default, reuseIdentifier: identifier)
        }

        cell.setup(row: info, book: book, source: source)
        return cell
    }
}
