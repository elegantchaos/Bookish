// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 11/01/2021.
//  All code (c) 2021 - present day, Sam Deane.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import BookishCore
import BookishImporter
import BookishImporterSamples
import CoreData
import Images
import KeyValueStore
import Logger
import SwiftUI
import ThreadExtensions

typealias AsyncImage = Images.AsyncImage

let modelChannel = Channel("Model")

protocol JSONCodable {
    static func decode(fromJSONCoding string: String) -> Self
    var encodeAsJSON: String { get }
}

extension UUID: JSONCodable {
    static func decode(fromJSONCoding string: String) -> UUID {
        UUID(uuidString: string) ?? UUID()
    }
    
    var encodeAsJSON: String {
        self.uuidString
    }
}

struct ImportProgress {
    let count: Int
    let total: Int
    let label: String
}

struct SelectionStats {
    let books: Int
    let items: Int
    
    init(selection: String?, context: NSManagedObjectContext) {
        if selection == .allBooksID {
            items = CDRecord.countOfKind(.book, in: context)
            books = items
        } else if let id = selection, let contents = CDRecord.withId(id, in: context)?.contents {
            items = contents.count
            books = contents.filter({ $0.kindCode == CDRecord.Kind.book.rawValue }).count
        } else {
            books = 0
            items = 0
        }
    }
}

class ModelController: ObservableObject {
    
    let stack: CoreDataStack
    let images = UIImageCache()
    
    @Published var selection: String? {
        willSet(newValue) {
            _selectionStats = nil
        }
    }
    
    var _selectionStats: SelectionStats?
    var selectionStats: SelectionStats {
        if _selectionStats == nil {
            _selectionStats = SelectionStats(selection: selection, context: stack.viewContext)
        }
        
        return _selectionStats!
    }
    
    init(stack: CoreDataStack) {
        self.stack = stack
        
        if let string = UserDefaults.standard.string(forKey: "selection") {
            onMainQueue {
                self.selection = string
            }
        }
    }
    
    var appName: String { "Bookish Lists" }
    
    func save() {
        UserDefaults.standard.set(selection, forKey: "selection")
        
        let context = stack.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    func delete(_ object: CDRecord) {
        print("deleting \(object.objectID)")
        if object.id == selection {
            print("cleared selection")
            selection = nil
        }
        let context = stack.viewContext
        context.perform {
            context.delete(object)
            onMainQueue {
                self.save()
            }
        }
    }
    
    func add(_ kind: CDRecord.Kind, setup: ((CDRecord) -> Void)? = nil) -> CDRecord {
        let object = CDRecord(in: stack.viewContext)
        
        object.kind = kind
        setup?(object)
        save()
        return object
    }
    
    func removeAllData() throws {
        objectWillChange.send()
        try stack.removeAllData()
    }

    func image(for book: CDRecord, usePlacholder: Bool = true) -> AsyncImage {
        if usePlacholder {
            return images.image(for: book.imageURL, default: "book")
        } else {
            return images.image(for: book.imageURL)
        }
    }
    
    func makeDefaultFields() -> FieldList {
        let list = FieldList()
        list.addField(Field(.description, kind: .paragraph, layout: .belowNoLabel))
        list.addField(Field(.notes, kind: .paragraph, layout: .below))
        list.addField(Field(.addedDate, kind: .date, label: "added"))
        list.addField(Field(.publishedDate, kind: .date, label: "published"))
        list.addField(Field(.format, kind: .string))
        list.addField(Field(.asin, kind: .string, icon: "barcode"))
        list.addField(Field(.isbn, kind: .string, icon: "barcode"))
        list.addField(Field(.dewey, kind: .string))
        list.addField(Field(.pages, kind: .number))
        return list
    }
    
    var roles: [String] { // TODO: make this editable by the user
        return ["author", "editor", "illustrator", "collaborator", "reviewer"]
    }
    
    lazy var sortedRoles = roles.sorted()
    
    lazy var defaultFields = makeDefaultFields()
    
    var canUndo: Bool {
        stack.viewContext.undoManager?.canUndo ?? false
    }
    
    func handleUndo() {
        objectWillChange.send()
        stack.viewContext.performAndWait {
            stack.viewContext.undoManager?.undo()
        }
    }
    
    var canRedo: Bool {
        stack.viewContext.undoManager?.canRedo ?? false
    }
    
    func handleRedo() {
        objectWillChange.send()
        stack.viewContext.performAndWait {
            stack.viewContext.undoManager?.redo()
        }
    }
    
    var selectedRecord: CDRecord? {
        guard let selection = selection, let record = CDRecord.withId(selection, in: stack.viewContext) else { return nil }
        return record
    }
}
