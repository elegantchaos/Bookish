// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 26/10/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Actions
import BookishModel
import AppKit

class ImporterAction: Action {
    class func standardActions() -> [Action] {
        return [
            FillImportMenuAction(identifier: "FillImportMenu"),
            ImportAction(identifier: "Import"),
        ]
    }
}

class ImportMergedAction: ImporterAction {
    func importer(for context: ActionContext) -> Importer? {
        let importManager = Application.sharedInstance.importManager // TODO: read from context?
        return importManager.importer(named: context.parameters[0])
    }
    override func validate(context: ActionContext) -> Bool {
        return importer(for: context)?.canImport ?? false
    }
    
    override func perform(context: ActionContext) {
        if let viewModel = context.info[ActionContext.viewModelKey] as? CollectionDocumentViewModel {
            let document = viewModel.document
            if let importer = importer(for: context) {
                importer.run(for: document)
            }
        }
    }
}

class ImportAction: ImporterAction {
    func importer(for context: ActionContext) -> Importer? {
        let importManager = Application.sharedInstance.importManager // TODO: read from context?
        return importManager.importer(named: context.parameters[0])
    }
    override func validate(context: ActionContext) -> Bool {
        return importer(for: context)?.canImport ?? false
    }
    
    override func perform(context: ActionContext) {
        if let document = (try? NSDocumentController.shared.openUntitledDocumentAndDisplay(false)) as? CollectionDocument {
            if let importer = importer(for: context) {
                importer.run(for: document)
            }
        }
    }
}

class FillImportMenuAction: ImporterAction {
    override func validate(context: ActionContext) -> Bool {
        guard super.validate(context: context) else {
            return false
        }
        
        if let item = context.sender as? NSMenuItem, let viewModel = context.info[ActionContext.viewModelKey] as? CollectionDocumentViewModel {
            item.submenu = viewModel.importMenu
            return true
        }
        
        return false
    }
}
