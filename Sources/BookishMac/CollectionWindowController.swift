// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 21/08/2018.
//  All code (c) 2018 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import AppKit
import BookishModel

class CollectionWindowController: NSWindowController, DocumentWindowController, ActionContextProvider {
    var viewModel: CollectionDocumentViewModel?
    typealias ViewModel = CollectionDocumentViewModel
    
    var bookIndexController: CollectionIndexViewController?
    var bookDetailController: CollectionDetailViewController?
    
    @IBAction func insertBook(_ sender: Any) {
        bookIndexController?.indexArray.add(sender)
//        if let context = viewModel?.managedObjectContext {
//            let request: NSFetchRequest<Book> = Book.fetchRequest()
//            let book = Book(context: context)
//            viewModel?.bookIndex?.setSelectedObjects([book])
//        }
    }
    
    func provide(context: ActionContext) {
        context.info[ActionContext.ModelObjectContextKey] = viewModel?.managedObjectContext
    }
}
