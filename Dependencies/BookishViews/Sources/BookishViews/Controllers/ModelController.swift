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

public class ModelController: ObservableObject {
    
    public let stack: CoreDataStack
    public let images = UIImageCache()
    
    public init(stack: CoreDataStack) {
        self.stack = stack
        makeRootLists()
    }
    
    var appName: String { "Bookish Lists" }

    public func save() {
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
        let context = stack.viewContext
        context.perform {
            context.delete(object)
            onMainQueue {
                self.save()
            }
        }
    }
    
    func add(_ kind: CDRecord.Kind, setup: ((CDRecord) -> Void)? = nil) -> CDRecord {
        let object = CDRecord.make(kind: kind, in: stack.viewContext)
        setup?(object)
        save()
        return object
    }
    
    public func removeAllData() throws {
        objectWillChange.send()
        try stack.removeAllData()
    }

    public func setupStandardData(using importController: ImportController) throws {
        try removeAllData()
        importController.import(from: BookishImporter.urlForSample(withName: "DeliciousSmall"))
    }
    
    func image(for book: CDRecord, usePlacholder: Bool = true) -> AsyncImage {
        if usePlacholder {
            return images.image(for: book.imageURL, default: "book")
        } else {
            return images.image(for: book.imageURL)
        }
    }
    
    // MARK: Root Lists
    
    typealias ListSetupFunction = (CDRecord, NSManagedObjectContext) -> Void
    
    func makeRootLists() {
        let context = stack.viewContext
        context.perform { [self] in
            makeRootList(.rootListsID, context: context, setup: makeDefaultLists)
            makeRootList(.rootRolesID, context: context, setup: makeDefaultRoles)
            save()
        }
    }
    
    @discardableResult func makeRootList(_ id: String, context: NSManagedObjectContext, setup: ListSetupFunction? = nil) -> CDRecord {
        return CDRecord.findOrMakeWithID(id, in: context) { created in
            created.kind = .root
            created.name = id.localized
            setup?(created, context)
        }
    }
    
    // MARK: Default Lists
    
    func defaultList(_ name: String, in context: NSManagedObjectContext) -> CDRecord {
        let id = "default.\(name)"
        guard let record = CDRecord.findWithID(id, in: context), record.kind == .list else {
            fatalError("missing list \(id)")
        }

        return record
    }
    
    func idForDefaultList(_ name: String) -> String {
        return "default.\(name)"
    }
    
    func makeDefaultLists(in container: CDRecord, context: NSManagedObjectContext) {
        let names = ["reading", "bookclub", "history", "library", "loan", "borrowed", "imports"]
             
        let date = Date()
        for name in names {
            let id = idForDefaultList(name)
            let list = CDRecord.make(kind: .list, in: context)
            list.id = id
            list.name = id.localized
            list.set("\(id).description".localized, forKey: .description)
            list.set(date, forKey: .addedDate)
            list.set(date, forKey: .modifiedDate)
            container.add(list)
        }
    }
    
    // MARK: Roles
    
    var roles: [CDRecord] {
        return defaultList("roles", in: stack.viewContext).contentsWithKind(.role)
    }
    
    var sortedRoles: [CDRecord] {
        return roles.sortedByName
    }
    
    func role(_ role: String, in context: NSManagedObjectContext) -> CDRecord {
        let id = "role.\(role)"
        guard let record = CDRecord.findWithID(id, in: context), record.kind == .role else {
            fatalError("missing role \(role)")
        }

        return record
    }

    func makeDefaultRoles(in container: CDRecord, context: NSManagedObjectContext) {
        let roles = ["author", "editor", "illustrator", "collaborator", "reviewer", "publisher", "series"]
        for role in roles {
            let list = CDRecord.make(kind: .role, in: context)
            let id = "role.\(role)"
            list.id = id
            list.name = id.localized
            container.add(list)
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
}

extension String {
    static let rootPreferencesID = "root.preferences"
    static let rootListsID = "root.lists"
    static let rootRolesID = "root.roles"
}
