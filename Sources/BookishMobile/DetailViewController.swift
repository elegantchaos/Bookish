// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 20/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel

class DetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
   let rows = DetailSpec.standardDetails
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "name")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "name")
        }

        if let label = cell?.textLabel {
            label.text = rows[indexPath.row].label
        }
        
        return cell!
    }
    

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var detailView: UITableView!

    func configureView() {
        // Update the user interface for the detail item.
        if let detail = detailItem {
            if let label = detailDescriptionLabel {
                label.text = detail.name
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
    }

    var detailItem: Book? {
        didSet {
            // Update the view.
            configureView()
        }
    }


}

