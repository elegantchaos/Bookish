// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Cocoa

class CollectionRootViewController: CollectionViewController {
    @IBOutlet weak var selectedMarkerConstraint: NSLayoutConstraint!
    @IBOutlet weak var selectedMarkerButton: NSButton!
    @IBOutlet weak var buttonContainer: NSView!
    @IBOutlet weak var mainView: NSView!
    
    let initialSplit: CGFloat = 256.0

    var buttons: [NSButton] = []

    var observer: NSKeyValueObservation?
    
    override func windowDidLoad(_ window: CollectionWindowController) {
        let mainContent: NSSplitViewController? = nearestIncludingChildren()
        mainContent?.splitView.setPosition(initialSplit, ofDividerAt: 0)

        super.windowDidLoad(window)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        let subviews = buttonContainer.subviews
        for view in subviews {
            if let button = view as? NSButton, button != selectedMarkerButton {
                buttons.append(button)
            }
        }
        
        observer = cvm.observe(\CollectionViewModel.modeIndex) { (cvm, change) in
            self.setMarker(to: cvm.modeIndex)
        }
        
        setMarker(to: cvm.modeIndex)
    }
    
    func setMarker(to index: Int) {
        if index < buttons.count {
            let button = buttons[index]
            let offset = (selectedMarkerButton.frame.height - button.frame.height) / 2.0
            let adjusted = buttonContainer.convert(button.frame, to: selectedMarkerButton.superview!)
            selectedMarkerConstraint.constant = adjusted.origin.y - offset
        }
    }
    
    @IBAction func selectRadio(_ sender: NSButton) {
        if let siblings = sender.superview?.subviews {
            for child in siblings {
                if let button = child as? NSButton {
                    button.state = .off
                }
            }
            sender.state = .on
            if let index = buttons.firstIndex(of: sender) {
                cvm.modeIndex = index
                setMarker(to: index)
            }
        }
    }
}

extension CollectionRootViewController: NSMenuItemValidation {
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(undo(_:)):
            return cvm.managedObjectContext.undoManager?.canUndo ?? false
            
        case #selector(redo(_:)):
            return cvm.managedObjectContext.undoManager?.canRedo ?? false
            
        default:
            return true
        }
    }
    @objc @IBAction func undo(_ sender: Any) {
        cvm.managedObjectContext.undoManager?.undo()
    }
    
    @IBAction func redo(_ sender: Any) {
        cvm.managedObjectContext.undoManager?.redo()
    }
    
}
