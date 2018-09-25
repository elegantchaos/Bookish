// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 13/09/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel
import Dispatch

class PersonDetailViewController: CollectionViewController {
    @IBOutlet weak var nameView: NSTextField!
    @IBOutlet weak var indexView: PersonIndexViewController!
    var indexObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        indexView = nearestSibling()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
//        if let window = view.window?.windowController as? CollectionWindowController {
//            window.bookDetailController = self
//        }
        
        if let indexArray = indexView.indexArray {
            nameView.bind(NSBindingName(rawValue: "value"), to:indexArray, withKeyPath:"selection.name", options: [:])
//            subtitleView.bind(NSBindingName(rawValue: "value"), to:indexArray, withKeyPath:"selection.subtitle", options: [:])
//            imageView.bind(NSBindingName(rawValue: "value"), to:indexArray, withKeyPath:"selection.image", options: [NSBindingOption.valueTransformerName:"CoverImage"])
            indexObserver = indexArray.observe(\NSArrayController.selection, changeHandler: { (index, change) in
                self.selectionChanged()
            })
            selectionChanged()
        }
    }
    
    override func viewWillDisappear() {
        indexObserver = nil
        super.viewWillDisappear()
    }

    func selectionChanged() {
//        let selectedCount = indexView.indexArray.selectedObjects?.count ?? 0
//        let showDetail = selectedCount > 0
//        detailsView.isHidden = !showDetail
//        if showDetail {
//            updatePeople()
//        }
        if let wc = view.window?.windowController as? CollectionWindowController {
            wc.validateButtons()
        }
    }

}
