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
            let vm = application.viewModel
            titleLabel.font = vm.titleFont
            subtitleLabel.font = vm.detailFont
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
        if let book = representedObject {
            context[ActionContext.selectionKey] = [book]
        }
        super.provide(context: context)
    }
    
    
    func prepareChooser<TargetType: ChooseItemTarget>(for segue: UIStoryboardSegue, sender: Any?, targetAdaptor: (UITableViewCell) -> TargetType) {
        if let controller = segue.destination as? ChooseEntityController<TargetType>, let button = sender as? UIButton {
            let popover = controller.popoverPresentationController
            popover?.sourceRect = button.frame
            popover?.sourceView = button.superview
            
            let origin = button.convert(button.bounds.origin, to: detailView)
            if let index = detailView.indexPathForRow(at: origin), let cell = detailView.cellForRow(at: index) {
                let target = targetAdaptor(cell)
                controller.setup(target: target, sort: application.viewModel.roleSorting, collection: application.collection)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "chooseRole":
            prepareChooser(for: segue, sender: sender) { (cell) -> ChooseRoleTarget in
                return ChooseRoleTarget(row: cell as! BookPersonRow)
            }
            
        case "choosePerson":
            prepareChooser(for: segue, sender: sender) { (cell) -> ChoosePersonTarget in
                return ChoosePersonTarget(row: cell as! BookPersonRow)
            }
            
        default:
            break
        }
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
