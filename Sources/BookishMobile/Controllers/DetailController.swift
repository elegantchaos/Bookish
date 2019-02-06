// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import CoreData
import BookishModel
import Actions
import Logger

let detailViewChannel = Logger("DetailView")

// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel
import Actions
import Logger

//class DetailController: UIViewController {
//    var representedObject: EntityType? {
//        didSet {
//            detailViewChannel.debug("represented object changed for \(entityName)")
//            configureView()
//        }
//    }
//
//}



class DetailControllerX: UIViewController, UITableViewDataSource, UITableViewDelegate, ActionContextProvider {
    typealias EntityType = ModelObject
    
    @IBOutlet weak var detailView: UITableView!
    @IBOutlet weak var editAction: UINavigationItem!

    var bindings = [Any]()
    var entityName = ""
    var representedObject: EntityType?
    var source: DetailProvider?
    
    lazy var placeholderImage = UIImage(named: "CoverPlaceholder")
    
    @IBOutlet weak var titleLabel: UITextField!
    @IBOutlet weak var subtitleLabel: UITextField!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        detailViewChannel.debug("view loaded for \(entityName)")
        
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
        navigationItem.leftItemsSupplementBackButton = true

        configureView()
    }
    
    func setup(for object: EntityType) {
        detailViewChannel.debug("setup for \(object)")
        representedObject = object
        source = (object as? DetailOwner)?.getProvider()
        configureView()
    }
    
    func configureView() {
        if let source = source, let object = representedObject, titleLabel != nil {
            let vm = application.viewModel
            titleLabel.font = vm.titleFont
            subtitleLabel.font = vm.detailFont
            if let path = source.titleProperty {
                bindings.append(TextFieldBinding(for: titleLabel, to: object, path: path))
                bindings.append(StringBinding(for: self, property: "title", to: object, path: path))
            }
            
            if let path = source.subtitleProperty {
                bindings.append(TextFieldBinding(for: subtitleLabel, to: object, path: path))
                subtitleLabel.isHidden = false
            } else {
                subtitleLabel.isHidden = true
            }
            
            configureImage(for: object)
            updateView()
        }
    }
    
        func reset() {
            navigationController?.popToRootViewController(animated: false)
            bindings = [Any]()
        }

    func updateView() {
        if let object = representedObject, titleLabel != nil {
            titleLabel.isEnabled = isEditing
            subtitleLabel.isEnabled = isEditing
            source?.filter(for: [object], editing: isEditing, context:application.viewModel)
            validateButtons()
        }
    }
    
    func configureImage(for object: EntityType) {
        if let data = object.value(forKey: "image") as? Data, let image = UIImage(data: data) {
            imageView.image = image
        } else {
            imageView.image = UIImage(named: "CoverPlaceholder")
            if let urlString = object.value(forKey: "imageURL") as? String, let url = URL(string: urlString) {
                application.imageCache.image(for: url) { (image) in
                    self.imageView.image = image
                }
            }
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return source?.sectionCount ?? 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return source?.sectionTitle(for: section)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source?.itemCount(for: section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let object = representedObject else { fatalError("should have object set") }
        if let info = source?.info(section: indexPath.section, row: indexPath.row) {
            let identifier = info.kind
            if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? DetailRow {
                cell.setup(row: info, object: object)
                return cell
            }

            detailViewChannel.log("Unregistered cell type \(identifier).")
        }
        
        fatalError("unregistered table cell")
    }
    

    
    func provide(context: ActionContext) {
        context[ToggleEditingAction.editableKey] = self
        if let book = representedObject {
            context[ActionContext.selectionKey] = [book]
        }
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
                return ChooseRoleTarget(row: cell as! PersonRow)
            }
            
        case "choosePerson":
            prepareChooser(for: segue, sender: sender) { (cell) -> ChoosePersonTarget in
                return ChoosePersonTarget(row: cell as! PersonRow)
            }
            
        default:
            break
        }
    }
    
}

extension DetailControllerX: EditableView {
    func setEditing(_ editing: Bool) {
        isEditing = editing
    }
    
    func didToggleEditing() {
        updateView()
        detailView.reloadData()
    }
}
