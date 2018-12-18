// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import CoreData
import BookishModel
import Actions

class CollectionController: UITabBarController {
    var observers = [NSKeyValueObservation]()
    var indexControllers: [String:Any] = [:]
    
    func reset(usingSample: Bool) {
        
        for controller in indexControllers.values {
            if let controller = controller as? EntityIndex {
                controller.reset()
            }
        }
        
        application.persistentContainer = CollectionContainer(name: "Default")
        application.persistentContainer.load(usingSample: usingSample, reset: true)
        
        for controller in indexControllers.values {
            if let controller = controller as? EntityIndex {
                controller.reload()
            }
        }
    }
    
    func setup(splitView: UISplitViewController) {
        let navigationController = splitView.viewControllers[splitView.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitView.displayModeButtonItem
        splitView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        application.collectionController = self
        for n in 0...3 {
            setup(splitView: viewControllers![n] as! UISplitViewController)
        }

        let viewModel = application.viewModel
        let modeObserver = application.observe(\Application.viewModel.modeIndex) { (app, change) in
            self.selectedIndex = viewModel.modeIndex
        }
        observers.append(modeObserver)
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        if let index = tabBar.items!.firstIndex(of: item) {
            application.viewModel.modeIndex = index
        }
    }

    func reveal<EntityType: NSManagedObject>(_ object: EntityType, mode: CollectionViewModel.Mode) {
        application.viewModel.mode = mode
        if let name = EntityType.entity().name {
            if let index = indexControllers[name] as? EntityIndex {
                index.select(object: object)
            }
        }
    }
}

extension CollectionController: BookViewer {
    @objc func reveal(book: Book) {
        reveal(book, mode: .books)
    }
}

extension CollectionController: PersonViewer {
    @objc func reveal(person: Person) {
        reveal(person, mode: .people)
    }
}

extension CollectionController: PublisherViewer {
    func reveal(publisher: Publisher) {
        reveal(publisher, mode: .publisher)
    }
}

extension CollectionController: SeriesViewer {
    func reveal(series: Series) {
        reveal(series, mode: .series)
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
