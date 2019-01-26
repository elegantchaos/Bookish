// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 17/12/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel
import Actions

class SeriesDetailController: DetailController<Series> {
    lazy var placeholderImage = UIImage(named: "SeriesPlaceholder")
    var sortedEntries = [SeriesEntry]()
    
    @IBOutlet weak var nameLabel: UITextField!
    @IBOutlet weak var notesView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func configureView() {
        if let series = representedObject, nameLabel != nil {
            bindings.append(TextFieldBinding(for: nameLabel, to: series, path: "name"))
            bindings.append(TextViewBinding(for: notesView, to: series, path: "notes", setIfNull: true))
            if let imageData = series.image {
                imageView.image = UIImage(data: imageData)
            } else {
                imageView.image = placeholderImage
            }
            
            let entries = series.entries?.sortedArray(using: application.viewModel.entrySorting) as! [SeriesEntry]
            sortedEntries.removeAll()
            sortedEntries.append(contentsOf: entries)
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortedEntries.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let entry = sortedEntries[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "book") as! SeriesBookRow // if we fail here, it's a coding error as all possible view types should have been registered
        if let book = entry.book {
            cell.setup(row: indexPath.row, book: book)
        }

        return cell
    }
}

