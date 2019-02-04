// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit

class RootController: UITableViewController {
    struct Item {
        let name: String
    }
    
    let items = [
        Item(name: "Books"),
        Item(name: "People"),
        Item(name: "Publishers"),
        Item(name: "Series")
        ]
        
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "item") as! RootRow
        let item = items[indexPath.row]
        cell.itemLabel.text = item.name
        cell.itemImage.image = UIImage(named: "\(item.name)Placeholder")
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        performSegue(withIdentifier: <#T##String#>, sender: <#T##Any?#>)
    }
 
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showIndex" {
            if let controller = segue.destination as? GenericIndexController {
                controller.entityName = "Book"
            }
        }
    }
}
