// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel
import Actions

class SeriesDetailController: UIViewController {
    lazy var placeholderImage = UIImage(named: "SeriesPlaceholder")
    var bindings = [Any]()
    var sortedEntries = [Entry]()
    
    @IBOutlet weak var nameLabel: UITextField!
    @IBOutlet weak var notesView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var detailView: UITableView!
    
    func configureView() {
        if let series = representedObject, nameLabel != nil {
            bindings.append(TextFieldBinding(for: nameLabel, to: series, path: "name"))
            bindings.append(TextViewBinding(for: notesView, to: series, path: "notes", setIfNull: true))
            if let imageData = series.image {
                imageView.image = UIImage(data: imageData)
            } else {
                imageView.image = placeholderImage
            }
            
            let entries = series.entries?.sortedArray(using: application.viewModel.entrySorting) as! [Entry]
            sortedEntries.removeAll()
            sortedEntries.append(contentsOf: entries)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    var representedObject: Series? {
        didSet {
            configureView()
        }
    }
    
}

// MARK: Table Support

extension SeriesDetailController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedEntries.count
    }
//
//    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        let index = sortedEntries[section].index
//        return "\(index)"
//    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = sortedEntries[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "book") as! SeriesBookRow // if we fail here, it's a coding error as all possible view types should have been registered
        if let book = entry.book {
            cell.setup(row: indexPath.row, book: book)
        }

        return cell
    }
}

