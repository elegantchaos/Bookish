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
    
    var viewModel: ViewModel? { get set }    
}

/**
 The view model contains state which is used by the views and controllers to display
 the model, but which isn't strictly part of the model.
 */

protocol WindowControllerViewModel {
    associatedtype WindowController: NSWindowController, WindowControllerWithViewModel
    associatedtype ViewControllerType: NSViewController, ViewControllerWithViewModel
}

/**
 Factory which can take in a view model instance, and create the corresponding window controller for it.
 
 During the creation process, the view model can be retrieved from the factory. This allows it to be fetched
 and set early on embedded view controllers, before they have access to their root controller/document/window.
 
 This helps to avoid problems with bindings that try to access model data too early, before the entire
 view hierarchy has been set up.
 
 Once the window is fully loaded, the factory also calls a notification method on any view controller in the hierarchy
 which implements the ViewControllerWithViewModel protocol.
 
 This is useful for wiring views together and performing other initialisation that can only happen once all views are
 present, but ideally needs to happen before any views are made visible (ie: after viewWillLoad has been called for all
 views, but before viewWillAppear has been called for any).
 
 */

class WindowControllerFactory<VM: WindowControllerViewModel> where VM.WindowController.ViewModel == VM, VM.ViewControllerType.ViewModel == VM {
    private var modelBeingCreated: VM?
    typealias FinishedLoadingCallback = (VM.WindowController) -> Void

    func instantiateController(for viewModel: VM, storyboard: String = "Main", identifier: String = "Document Window Controller") -> VM.WindowController {
        assert(modelBeingCreated == nil)
        modelBeingCreated = viewModel
        let storyboard = NSStoryboard(name: NSStoryboard.Name(storyboard), bundle: nil)
        var windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(identifier)) as! VM.WindowController
        windowController.viewModel = viewModel
        if let controller = windowController.window?.contentViewController {
            notifyFinishedLoading(window: windowController, controller: controller)
        }

        modelBeingCreated = nil
        return windowController
    }
    
    var viewModel: VM {
        return modelBeingCreated!
    }
    
    func notifyFinishedLoading(window: VM.WindowController, controller: NSViewController) {
        for child in controller.children {
            if let vc = child as? VM.ViewControllerType {
                vc.windowDidLoad(window)
            }
            notifyFinishedLoading(window: window, controller: child)
        }
    }
}
