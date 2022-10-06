//
//  CDRecord+CoreData.swift
//  BookishLists
//
//  Created by Sam Deane on 23/11/2021.
//

import CoreData
import Logger

let coreDataChannel = Channel("Core Data")

// MARK: CoreData Backed Properties

extension CDRecord {
    @NSManaged public var id: String
    @NSManaged public var name: String
    @NSManaged public var kindCode: Int16
    @NSManaged public var imageData: Data?
    @NSManaged public var imageURL: URL?
    @NSManaged internal var codedProperties: String?
    @NSManaged public var properties: Set<CDProperty>?
    @NSManaged public var contents: Set<CDRecord>?
    @NSManaged public var containedBy: Set<CDRecord>?
}

// MARK: Child Records

extension  CDRecord {
    @objc(addContentsObject:)
    @NSManaged public func addToContents(_ record: CDRecord)

    @objc(removeContentsObject:)
    @NSManaged public func removeFromContents(_ record: CDRecord)

    @objc(addContents:)
    @NSManaged public func addToContents(_ records: NSSet)

    @objc(removeContents:)
    @NSManaged public func removeFromContents(_ records: NSSet)

    func contains(_ value: CDRecord) -> Bool {
        guard let contents else { return false }
        return contents.contains(value)
    }
    
    func containedBy(_ value: CDRecord) -> Bool {
        guard let containedBy else { return false }
        return containedBy.contains(value)
    }
}

// MARK: Property Records

extension CDRecord {
    @objc(addPropertiesObject:)
    @NSManaged public func addToProperties(_ value: CDProperty)

    @objc(removePropertiesObject:)
    @NSManaged public func removeFromProperties(_ value: CDProperty)

    @objc(addProperties:)
    @NSManaged public func addToProperties(_ values: NSSet)

    @objc(removeProperties:)
    @NSManaged public func removeFromProperties(_ values: NSSet)

}


// MARK: Lookup / Creation

extension CDRecord {

    @nonobjc public class func fetchRequest(predicate: NSPredicate?, sort: [NSSortDescriptor]? = nil) -> NSFetchRequest<CDRecord> {
        let request = NSFetchRequest<CDRecord>(entityName: "CDRecord")
        request.predicate = predicate
        request.sortDescriptors = sort
        return request
    }

    typealias CreationCallback = (CDRecord) -> ()

    override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID().uuidString
    }

    class func withId(_ identifier: String, in context: NSManagedObjectContext) -> CDRecord? {
        let request = fetchRequest(predicate: NSPredicate(format: "id = %@", identifier))
        if let results = try? context.fetch(request), let object = results.first {
            return object
        }
        
        return nil
    }
    
    class func findWithID(_ identifier: String, in context: NSManagedObjectContext) -> CDRecord? {
        let request = fetchRequest(predicate: NSPredicate(format: "id = %@", identifier))
        if let results = try? context.fetch(request), let object = results.first {
            return object
        }
        
        return nil
    }
    
    class func findOrMakeWithID(_ identifier: String, in context: NSManagedObjectContext, creationCallback: CreationCallback) -> CDRecord {
        let request = fetchRequest(predicate: NSPredicate(format: "id = %@", identifier))
        if let results = try? context.fetch(request), let object = results.first {
            return object
        }

        let object = CDRecord(context: context)
        object.id = identifier
        creationCallback(object)
        assert(object.kind != .unknown, "callback should have set kind")
        return object
    }

    class func make(kind: RecordKind, in context: NSManagedObjectContext) -> CDRecord {
        let record = CDRecord(context: context)
        record.kind = kind
        return record
    }
    
    class func withName(_ name: String, in context: NSManagedObjectContext) -> CDRecord? {
        let request = CDRecord.fetchRequest(predicate: NSPredicate(format: "name = %@", name))
        if let results = try? context.fetch(request), let object = results.first {
            return object
        }
        
        return nil
    }
    
    class func findOrMakeWithName(_ name: String, kind: RecordKind? = nil, in context: NSManagedObjectContext, creationCallback: CreationCallback? = nil) -> CDRecord {
        let predicate: NSPredicate
        if let kindCode = kind?.rawValue {
            predicate = NSPredicate(format: "(name = %@) and (kindCode = \(kindCode))", name)
        } else {
            predicate = NSPredicate(format: "name = %@", name)
        }

        let request = CDRecord.fetchRequest(predicate: predicate)
        if let results = try? context.fetch(request), let object = results.first {
            return object
        }

        let object = CDRecord(context: context)
        object.name = name
        if let kindCode = kind?.rawValue {
            object.kindCode = kindCode
        }
        
        if let callback = creationCallback {
            callback(object)
        }
        
        assert(object.kind != .unknown, "callback or caller should have set kind")

        return object
    }

    class func countOfKind(_ kind: RecordKind, in context: NSManagedObjectContext) -> Int {
        let request = CDRecord.fetchRequest(predicate: NSPredicate(format: "kindCode = \(kind.rawValue)"))
        request.resultType = .countResultType
        if let count = try? context.count(for: request) {
            return count
        }
        
        return 0
    }

}
