// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel
import Actions

class DetailDataSource {
    let details = DetailSpec.standardDetails
    var people = [PersonRole]()
    
    var rows: Int {
        return details.count + people.count
    }
    
    func identifier(for row: Int) -> String {
        if row < people.count {
            return "person"
        } else {
            return "detail"
        }
    }
    
    func details(for row: Int) -> DetailSpec {
        return details[row - people.count]
    }
    
    func person(for row: Int) -> PersonRole {
        return people[row]
    }
    
}
class DetailViewController: UIViewController {
    
    let source = DetailDataSource()
    let sorting = [NSSortDescriptor(key: "role.name", ascending: true)]
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var detailView: UITableView!

    func configureView() {
        if let book = representedObject, titleLabel != nil {
            titleLabel.text = book.name
            subtitleLabel.text = book.subtitle
            if let imageData = book.image {
                imageView.image = UIImage(data: imageData)
            } else {
                imageView.image = UIImage(named: "CoverPlaceholder") // TODO: cache this
            }
            self.title = book.name
            if let roles = book.personRoles, let sorted = roles.sortedArray(using: sorting) as? [PersonRole] {
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

extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return source.rows
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = source.identifier(for: indexPath.row)
        var cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? DetailRow
        
        if identifier == "detail" {
            if cell == nil {
                cell = DetailRow(style: .default, reuseIdentifier: identifier)
            }
            
            let rowInfo = source.details(for: indexPath.row)
            cell?.label.text = rowInfo.label
            cell?.detail.text = representedObject?.value(forKey: rowInfo.binding) as? String
        } else {
            if cell == nil {
                cell = DetailRow(style: .default, reuseIdentifier: identifier)
            }
            
            let personRole = source.person(for: indexPath.row)
            cell?.label.text = personRole.role?.name
            cell?.detail.text = personRole.person?.name
        }
        return cell!
    }
}

// MARK: Action Support

extension DetailViewController: ActionContextProvider {
    func provide(context: ActionContext) {
        print("detail")
    }
}
