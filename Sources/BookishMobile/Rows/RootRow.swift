// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 01/02/2019.
//  All code (c) 2019 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel

class RootRow: UITableViewCell {
    
    var item: CollectionController.Item?
    
    func setup(for item: CollectionController.Item) {
        self.item = item
    }
}

class RootCategoryRow: RootRow {
    @IBOutlet weak var itemLabel: UILabel!
    @IBOutlet weak var itemImage: UIImageView!
    
    override func setup(for item: CollectionController.Item) {
        super.setup(for: item)
        if let entity = item.entity {
            itemLabel.text = entity.entityTitle
            itemImage.image = UIImage(named: entity.entityPlaceholder)
        }
    }
}

class RootIntroRow: RootRow, UITextViewDelegate {
    @IBOutlet weak var itemText: UITextView!
    
    override func setup(for item: CollectionController.Item) {
        super.setup(for: item)
        if let url = Bundle.main.url(forResource: "Help", withExtension: ".rtf"), let text = try? NSAttributedString(url: url, options: [:], documentAttributes: nil) {
            itemText.attributedText = text
            itemText.delegate = self
        }
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.scheme == "action" {
            switch URL.host {
            case "search":
                print("searching")
                
            case "add":
                application.collectionController.performSegue(withIdentifier: "showScanner", sender: self)
                
            default:
                print("unhandled action \(URL)")
            }
        }
        return false
    }
}
