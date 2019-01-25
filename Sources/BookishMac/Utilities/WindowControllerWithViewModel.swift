// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

/**
 View controllers that implement this protocol get notified once the window
 that they are in has completely finished loading.
 */

protocol ViewControllerWithViewModel {
    associatedtype ViewModel: WindowControllerViewModel
    func windowDidLoad(_ window: ViewModel.WindowController)
}

/**
 Window controllers that implement this protocol have an associated viewModel object.
 
 This contains state which is used by the views and controllers to display
 the model, but which isn't strictly part of the model and doesn't get persisted with it.
 */

protocol WindowControllerWithViewModel {
    associatedtype ViewModel: WindowControllerViewModel
    
    var viewModel: ViewModel { get }
    
    func didConnect(to: ViewModel)
}

/**
 The view model contains state which is used by the views and controllers to display
 the model, but which isn't strictly part of the model.
 */

protocol WindowControllerViewModel {
    associatedtype WindowController: NSWindowController, WindowControllerWithViewModel
    associatedtype ViewController: NSViewController, ViewControllerWithViewModel

    func didConnect(to: WindowController )
}

/**
 Factory which can take in a view model instance, create a window controller from a storyboard, and associate
 the view model with it.
 
 During the creation process, the view model can be retrieved from the factory. This allows it to be fetched
 and set early on embedded view controllers, before they have access to their root controller/document/window.
 
 This helps to avoid problems with bindings that try to access model data too early, before the entire
 view hierarchy has been set up.
 
 Once the window is fully loaded, the factory also calls a notification method on any view controller in the hierarchy
 which implements the ViewControllerWithViewModel protocol.
 
 This is useful for wiring views together and performing other initialisation that can only happen once all views are
 present, but ideally needs to happen before any views are made visible (ie: after viewDidLoad has been called for all
 views, but before viewWillAppear has been called for any).
 
 */

class WindowControllerFactory<ViewModel: WindowControllerViewModel> where ViewModel.WindowController.ViewModel == ViewModel, ViewModel.ViewController.ViewModel == ViewModel {
    private var modelBeingCreated: ViewModel?
    typealias FinishedLoadingCallback = (ViewModel.WindowController) -> Void

    func instantiateController(for viewModel: ViewModel, storyboard: String = "Main", identifier: String = "Document Window Controller") -> ViewModel.WindowController {
        let savedViewModel = modelBeingCreated
        modelBeingCreated = viewModel
        
        let storyboard = NSStoryboard(name: NSStoryboard.Name(storyboard), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(identifier)) as! ViewModel.WindowController
        windowController.didConnect(to: viewModel)
        viewModel.didConnect(to: windowController)
        
        if let controller = windowController.window?.contentViewController {
            notifyFinishedLoading(window: windowController, controller: controller)
        }

        modelBeingCreated = savedViewModel
        return windowController
    }
    
    var viewModel: ViewModel {
        return modelBeingCreated!
    }
    
    func notifyFinishedLoading(window: ViewModel.WindowController, controller: NSViewController) {
        (controller as? ViewModel.ViewController)?.windowDidLoad(window)
        for child in controller.children {
            notifyFinishedLoading(window: window, controller: child)
        }
    }
}
