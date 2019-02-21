// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import ActionsKit
import BookishModel
import AppKit

/**
 Represents a request to import into a document using a given importer.
 */

class ImportRequest {
    let importer: Importer
    let collection: SyncedCollection
    
    init(importer: Importer, collection: SyncedCollection) {
        self.importer = importer
        self.collection = collection
    }
    
    /**
     Queue the request.
     
     If we know the url already, we just run the request.
     If not, we ask the user for a URL, and if they give us one, we run the request using it.
     */
    
    func queue() {
        if importer.source == .knownLocation {
            if let url = importer.defaultImportLocation {
                run(for: url)
            }
        } else {
            askForURL()
        }
    }
    
    /**
     Make an open documents panel to request the document to import.
     */
    
    func makeOpenPanel() -> NSOpenPanel {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        return panel
    }
    
    /**
     Run the import for a given url.
     */
    
    func run(for url: URL) {
        importer.run(importing: url, into: collection.managedObjectContext) {
            self.complete()
        }
    }
    
    
    /**
     Ask the user for a file to import.
     
     The default implementation does this as a modal window, not
     attached to any document.
     */
    
    func askForURL() {
        let panel = self.makeOpenPanel()
        if let window = Application.sharedInstance.windowController.window {
            panel.beginSheetModal(for: window) { (response) in
                if let url = panel.url {
                    self.run(for: url)
                }
            }
        } else {
            panel.runModal()
            if let url = panel.url {
                self.run(for: url)
            }
        }
    }
    
    /**
     Perform tasks once the import has completed.
     */
    
    func complete() {
        collection.save()
    }
}

/**
 Represents a request to import into an existing document.
 */

class MergeImportRequest: ImportRequest {
    
    
}

/**
 Represents a request to import into a new document.
 */

class NewImportRequest: ImportRequest {
    init?(importer: Importer) throws {
        let application = Application.sharedInstance
        
        let oldMode = application.mode
        defer { application.mode = oldMode }
        
        application.mode = .defaultRoles
        super.init(importer: importer, collection: application.viewModel!.collection)
    }
    
    override func run(for url: URL) {
        collection.reset() { (collection, error) in
            if error == nil {
                super.run(for: url)
            }
        }
    }
}

/**
 Base class for all importer related actions.
 */

class ImporterAction: Action {
    class func standardActions() -> [Action] {
        return [
            ImportNewAction(identifier: "ImportNew"),
            ImportMergedAction(identifier: "ImportMerged"),
            FillImportMenuAction(identifier: "FillImportMenu"),
            FillMergeMenuAction(identifier: "FillMergeMenu")
        ]
    }
    
    class func makeImportMenu(action: String) -> NSMenu {
        let menu = NSMenu()
        let importManager = Application.sharedInstance.importManager
        for importer in importManager.sortedImporters {
            var title = importer.name
            if importer.source == .userSpecifiedFile {
                title.append("…")
            }
            let item = NSMenuItem(title: title, action: ActionManagerMac.Responder.performActionSelector, keyEquivalent: "")
            item.identifier = NSUserInterfaceItemIdentifier(rawValue: "menu.\(action).\(importer.name)")
            menu.addItem(item)
        }
        return menu
    }
}

/**
 Run an importer, merging the records into an existing document.
 */

class ImportMergedAction: ImporterAction {
    func importer(for context: ActionContext) -> Importer? {
        let importManager = Application.sharedInstance.importManager // TODO: read from context?
        return importManager.importer(named: context.parameters[0])
    }
    
    override func validate(context: ActionContext) -> Bool {
        let viewModel = context.info[ActionContext.viewModelKey] as? CollectionViewState
        return (viewModel != nil) && (importer(for: context)?.canImport ?? false)
    }
    
    override func perform(context: ActionContext) {
        if let viewModel = context.info[ActionContext.viewModelKey] as? CollectionViewState {
            if let importer = importer(for: context) {
                let request = MergeImportRequest(importer: importer, collection: viewModel.collection)
                request.queue()
            }
        }
    }
}

/**
 Run an importer, creating a new document with the results.
 */

class ImportNewAction: ImporterAction {
    func importer(for context: ActionContext) -> Importer? {
        let importManager = Application.sharedInstance.importManager // TODO: read from context?
        return importManager.importer(named: context.parameters[0])
    }
    
    override func validate(context: ActionContext) -> Bool {
        return importer(for: context)?.canImport ?? false
    }
    
    override func perform(context: ActionContext) {
        if let importer = importer(for: context) {
            if let request = try? NewImportRequest(importer: importer) {
                request?.queue()
            }
        }
    }
}

/**
 Fill the import menu with a list of importers.
 
 This action is never performed, it just populates a menu when it is validated.
 */

class FillImportMenuAction: ImporterAction {
    override func validate(context: ActionContext) -> Bool {
        guard super.validate(context: context) else {
            return false
        }
        
        if let item = context.sender as? NSMenuItem {
            item.submenu = ImporterAction.makeImportMenu(action: "ImportNew")
            return true
        }
        
        return false
    }
}

/**
 Fill the import menu with a list of importers.
 
 This action is never performed, it just populates a menu when it is validated.
 */

class FillMergeMenuAction: ImporterAction {
    override func validate(context: ActionContext) -> Bool {
        guard super.validate(context: context) else {
            return false
        }
        
        if let item = context.sender as? NSMenuItem, let _ = context.info[ActionContext.viewModelKey] as? CollectionViewState {
            item.submenu = ImporterAction.makeImportMenu(action: "ImportMerged")
            return true
        }
        
        return false
    }
}
