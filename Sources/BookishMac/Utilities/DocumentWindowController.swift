// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 23/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit

/**
 A document window controller always has an associated viewModel object.
 
 This contains state which is used by the views and controllers to display
 the model, but which isn't strictly part of the model.
 */

protocol DocumentWindowController {
    associatedtype ViewModel: DocumentViewModel
    var viewModel: ViewModel? { get set }    
}

/**
 The view model contains state which is used by the views and controllers to display
 the model, but which isn't strictly part of the model.
 */

protocol DocumentViewModel {
    associatedtype WindowController: DocumentWindowController
}

/**
 Factory which can take in a view model instance, and create the corresponding window controller for it.
 
 During the creation process, the view model can be retrieved from the factory. This allows it to be fetched
 and set early on embedded view controllers, before they have access to their root controller/document/window.
 
 This helps to avoid problems with bindings that try to access model data too early, before the entire
 view hierarchy has been set up.
 */

class DocumentWindowControllerFactory<VM: DocumentViewModel> where VM.WindowController.ViewModel == VM {
    private var modelBeingCreated: VM?
    typealias FinishedLoadingCallback = (VM.WindowController) -> Void
    private var callbacks = [FinishedLoadingCallback]()

    func instantiateController(for viewModel: VM, storyboard: String = "Main", identifier: String = "Document Window Controller") -> VM.WindowController {
        assert(modelBeingCreated == nil)
        modelBeingCreated = viewModel
        let storyboard = NSStoryboard(name: NSStoryboard.Name(storyboard), bundle: nil)
        var windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier(identifier)) as! VM.WindowController
        windowController.viewModel = viewModel
        for callback in callbacks {
            callback(windowController)
        }
        modelBeingCreated = nil
        return windowController
    }
    
    var viewModel: VM {
        return modelBeingCreated!
    }
    
    func onFinishedLoading(callback: @escaping FinishedLoadingCallback) {
        callbacks.append(callback)
    }
}
