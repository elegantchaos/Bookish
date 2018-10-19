// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel
import Actions

class DetailViewController: UIViewController {
    
   let rows = DetailSpec.standardDetails

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
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "detail") as? DetailRow
        if cell == nil {
            cell = DetailRow(style: .default, reuseIdentifier: "detail")
        }
        
        let rowInfo = rows[indexPath.row]
        cell?.label.text = rowInfo.label
        cell?.detail.text = representedObject?.value(forKey: rowInfo.binding) as? String
        return cell!
    }
}

// MARK: Action Support

extension DetailViewController: ActionContextProvider {
    func provide(context: ActionContext) {
        print("detail")
    }
}
