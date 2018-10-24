// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import BookishModel
import Actions

protocol RootUIProvider {
    func reveal(book: Book)
    func reveal(person: Person)
}

class RevealBookAction: Action {
    override func validate(context: ActionContext) -> Bool {
        let book = context.info[BookAction.bookKey] as? Book
        return (book != nil) && super.validate(context: context)
    }
    
    override func perform(context: ActionContext) {
        if let book = context.info[BookAction.bookKey] as? Book,
            let root = context.info[ActionContext.rootKey] as? RootUIProvider {
            root.reveal(book: book)
        }
    }
}

class CollectionController: UITabBarController, RootUIProvider {
    var observers = [NSKeyValueObservation]()
    var personIndexController: PersonIndexController!
    var bookIndexController: BookIndexController!
    
    func setup(splitView: UISplitViewController) {
        let navigationController = splitView.viewControllers[splitView.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitView.displayModeButtonItem
        splitView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        application.collectionController = self
        setup(splitView: viewControllers![0] as! UISplitViewController)
        setup(splitView: viewControllers![1] as! UISplitViewController)
        
        let modeObserver = application.observe(\Application.viewModel.modeIndex) { (app, change) in
            print("mode changed")
        }
        observers.append(modeObserver)
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let index = tabBar.items!.firstIndex(of: item) {
            application.viewModel.modeIndex = index
        }
    }

    @objc func reveal(person: Person) {
        application.viewModel.mode = .people
    }
    
    @objc func reveal(book: Book) {
        application.viewModel.mode = .books
    }

}

extension CollectionController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        
        if let topAsDetailController = secondaryAsNavController.topViewController as? BookDetailController {
            if topAsDetailController.representedObject == nil {
                // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                return true
            }
        }
        
        if let topAsDetailController = secondaryAsNavController.topViewController as? PersonDetailController {
            if topAsDetailController.representedObject == nil {
                // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                return true
            }
        }
        
        return false
    }

}
