// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 24/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import UIKit
import CoreData
import BookishModel
import Actions

class ApplicationRootController: UISplitViewController {
    var observers = [NSKeyValueObservation]()
    
    var indexControllers: [String:Any] = [:]
    
    func reset(mode: CollectionContainer.PopulateMode) {
        let indices = indexControllers.values.compactMap { $0 as? EntityIndex }
        indices.forEach { $0.reset() }
        
        application.collection.delete(remove: true)
        application.collection = application.setupCollection(mode: mode)
        
        indices.forEach { $0.reload() }
    }
    
    func setup(splitView: UISplitViewController) {
        let navigationController = splitView.viewControllers[splitView.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitView.displayModeButtonItem
        splitView.delegate = self
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        application.collectionController = self
//        for n in 0...3 {
//            setup(splitView: viewControllers![n] as! UISplitViewController)
//        }

        let viewModel = application.viewModel
//        self.selectedIndex = viewModel.modeIndex
//        let modeObserver = application.observe(\Application.viewModel.modeIndex) { (app, change) in
//            self.selectedIndex = viewModel.modeIndex
//        }
//
//        observers.append(modeObserver)
    }
    
//    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
//        if let index = tabBar.items!.firstIndex(of: item) {
//            application.viewModel.modeIndex = index
//        }
//    }

    func reveal<EntityType: NSManagedObject>(_ object: EntityType, mode: CollectionViewModel.Mode) {
        application.viewModel.mode = mode
        let name = String(describing: EntityType.self)
        if let index = indexControllers[name] as? EntityIndex {
            index.select(object: object)
        }
    }
}

extension ApplicationRootController: BookViewer {
    @objc func reveal(book: Book) {
        reveal(book, mode: .books)
    }
}

extension ApplicationRootController: PersonViewer {
    @objc func reveal(person: Person) {
        reveal(person, mode: .people)
    }
}

extension ApplicationRootController: PublisherViewer {
    func reveal(publisher: Publisher) {
        reveal(publisher, mode: .publisher)
    }
}

extension ApplicationRootController: SeriesViewer {
    func reveal(series: Series) {
        reveal(series, mode: .series)
    }
}

extension ApplicationRootController: UISplitViewControllerDelegate {
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        
        if let topAsDetailController = secondaryAsNavController.topViewController as? DetailController {
            if topAsDetailController.representedObject == nil {
                // Return true to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
                return true
            }
        }
        
        return false
    }

}
