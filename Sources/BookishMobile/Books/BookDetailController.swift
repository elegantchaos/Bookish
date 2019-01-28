// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel
import Actions
import Logger

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
            configureImage(for: book)
            bindings.append(StringBinding(for: self, property: "title", to: book, path: "name"))
            updateView()
        }
    }
    
    func updateView() {
        if let book = representedObject, titleLabel != nil {
            titleLabel.isEnabled = isEditing
            subtitleLabel.isEnabled = isEditing
            source.filter(for: [book], editing: isEditing)
            validateButtons()
        }
    }
    
    func configureImage(for book: Book) {
        if let data = book.image, let image = UIImage(data: data) {
            imageView.image = image
        } else {
            imageView.image = UIImage(named: "CoverPlaceholder")
            if let urlString = book.imageURL, let url = URL(string: urlString) {
                application.imageCache.image(for: url) { (image) in
                    self.imageView.image = image
                }
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.rows
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let book = representedObject else { fatalError("should have book set") }
        let info = source.info(for: indexPath.row)
        let identifier = info.kind.rawValue
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? BookDetailRow else {
            detailViewChannel.log("Unregistered cell type \(identifier).")
            return UITableViewCell(style: .default, reuseIdentifier: identifier)
        }

        cell.setup(row: info, book: book, source: source)
        return cell
    }

    override func provide(context: ActionContext) {
        context[ToggleEditingAction.editableKey] = self
        super.provide(context: context)
    }
}

extension BookDetailController: EditableView {
    func setEditing(_ editing: Bool) {
        isEditing = editing
    }
    
    func didToggleEditing() {
        updateView()
        detailView.reloadData()
    }
}
