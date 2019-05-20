// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import Actions
import BookishModel
import Logger

let validationChannel = Logger("Validation")

class CollectionWindowController: LateAutosavingWindowController, NSWindowDelegate, ActionContextProvider {
    fileprivate var cvm: CollectionViewState!
    var scannerWindow: ScannerWindowController?
    
    override var lateAutosaveName: String? { return "collection.window" }
    private var indexControllers: [String:Any] = [:]
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        window?.autorecalculatesKeyViewLoop = false
    }
    
    func provide(context: ActionContext) {
        context.info[ActionContext.modelKey] = cvm.managedObjectContext
        context.info[ActionContext.viewModelKey] = cvm
        context.info[ActionContext.windowKey] = self
        context.info[ActionContext.rootKey] = self
        context.info[LookupCoverAction.managerKey] = application.lookupManager
    }

    
    func pushInitialObject() {
        // push the selection from the initial index controller onto the navigation stack
        let name = cvm.mode.singularName()
        if let index = indexControllers[name] as? IndexController {
            index.fetchIfNecessary() {
                if let objects = index.indexArray.arrangedObjects as? Array<ModelObject>, let first = objects.first {
                    self.cvm.navigationStack.push(first)
                    index.select(items: [first], forceUpdate: true) {
                        self.showWindow(self)
                    }
                } else {
                    // we've got no objects
                    self.showWindow(self)
                }
            }
        }
    }
    
    func navigateBack(completed: @escaping Action.Completion) {
        if let object = cvm.navigationStack.goBack() {
            reveal(object: object, pushOntoStack: false)
        }
        completed()
    }
    
    func navigateForward(completed: @escaping Action.Completion) {
        if let object = cvm.navigationStack.goForward() {
            reveal(object: object, pushOntoStack: false)
        }
        completed()
    }
    
    func reveal(index: Int) {
        cvm.modeIndex = index
        let name = cvm.mode.singularName()
        if let index = indexControllers[name] as? IndexController {
            index.updateDetailView()
        }
    }
    
    func reveal(object: ModelObject, pushOntoStack: Bool = true, forEditing: Bool = false) {
        let entityName = type(of:object).entityName
        if let index = indexControllers[entityName] as? IndexController {
            if pushOntoStack {
                cvm.navigationStack.push(object)
            }
            let mode = CollectionViewState.Mode.named(entityName)
            let modeChanged = mode != cvm.mode
            cvm.mode = mode
            index.select(items: [object], forEditing: forEditing, forceUpdate: modeChanged)
        }
    }
    
    func register(index controller: IndexController, for entityName: String) {
        indexControllers[entityName] = controller
    }
    
    fileprivate func setupScannerWindow() -> ScannerWindowController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let window = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("ScannerWindow")) as! ScannerWindowController
        
        return window
    }
    
    func toggleScanner() {
        if scannerWindow == nil {
            scannerWindow = setupScannerWindow()
            if let window = window, let scanner = scannerWindow?.window {
                window.beginSheet(scanner)
            }
        } else {
            scannerWindow?.close()
            scannerWindow = nil
        }
    }
    
    func showPanel<Panel: NSSavePanel>(_ panel: Panel, completion: @escaping (NSApplication.ModalResponse) -> Void) {
        if let window = window {
            panel.beginSheetModal(for: window) { (response) in
                completion(response)
            }
        } else {
            let response = panel.runModal()
            completion(response)
        }
        
    }
}

extension CollectionWindowController: WindowControllerWithViewModel {
    var viewModel: CollectionViewState {
        return cvm
    }
    
    typealias ViewModel = CollectionViewState
    
    func didConnect(to viewModel: CollectionViewState) {
        self.cvm = viewModel
    }
}

extension CollectionWindowController: BookViewer {
    @objc func reveal(book: Book) {
        reveal(object: book)
    }
}

extension CollectionWindowController: PersonViewer {
    @objc func reveal(person: Person) {
        reveal(object: person)
    }
}

extension CollectionWindowController: PublisherViewer {
    func reveal(publisher: Publisher) {
        reveal(object: publisher)
    }
}

extension CollectionWindowController: SeriesViewer {
    func reveal(series: Series) {
        reveal(object: series)
    }
}

extension CollectionWindowController: RoleViewer {
    func reveal(role: Role) {
        reveal(object: role)
    }
}
