// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/09/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation

extension CDRecord {
    
    func contentsWithKind(_ kind: RecordKind) -> [CDRecord] {
        let kindCode = kind.rawValue
        guard let contents = contents else { return [] }
        return contents.filter { $0.kindCode == kindCode }
    }

    func contentsExcludingKind(_ kind: RecordKind) -> [CDRecord] {
        let kindCode = kind.rawValue
        guard let contents = contents else { return [] }
        return contents.filter { $0.kindCode != kindCode }
    }

    func findChildWithName(_ name: String, kind: RecordKind? = nil) -> CDRecord? {
        guard let contents = contents else { return nil }
        
        let possibles = contents.filter { $0.name == name }
        
        if let kind {
            return possibles.first { $0.kind == kind }
        } else {
            if possibles.count > 1 {
                coreDataChannel.log("More than one child found with name “\(name)”. Return first.")
            }
            
            return possibles.first
        }
    }
    
    func findOrMakeChildWithName(_ name: String, kind: RecordKind, creationCallback: CreationCallback? = nil) -> CDRecord {
        let kindCode = kind.rawValue
        if let existing = contents?.first(where: { ($0.kindCode == kindCode) && ($0.name == name) }) {
            return existing
        }
        
        let new = CDRecord.make(kind: kind, in: managedObjectContext!)
        new.name = name
        addToContents(new)
        if let callback = creationCallback {
            callback(new)
        }
        
        return new
    }
    
    func findChildWithID(_ id: String, kind: RecordKind? = nil) -> CDRecord? {
        guard let contents = contents else { return nil }
        
        let possibles = contents.filter { $0.id == id }
        
        if let kind {
            return possibles.first { $0.kind == kind }
        } else {
            if possibles.count > 1 {
                coreDataChannel.log("More than one child found with id “\(id)”. Return first.")
            }
            
            return possibles.first
        }
    }
    
    func findOrMakeChildWithID(_ id: String, kind: RecordKind, creationCallback: CreationCallback? = nil) -> CDRecord {
        let kindCode = kind.rawValue
        if let existing = contents?.first(where: { ($0.kindCode == kindCode) && ($0.id == id) }) {
            return existing
        }
        
        let new = CDRecord.make(kind: kind, in: managedObjectContext!)
        new.id = id
        addToContents(new)
        
        if let callback = creationCallback {
            callback(new)
        }
        
        return new
    }

    func containersWithKind(_ kind: RecordKind) -> [CDRecord] {
        let kindCode = kind.rawValue
        guard let containedBy else { return [] }
        return containedBy.filter { $0.kindCode == kindCode }
    }

    func containersExcludingKind(_ kind: RecordKind) -> [CDRecord] {
        let kindCode = kind.rawValue
        guard let containedBy else { return [] }
        return containedBy.filter { $0.kindCode != kindCode }
    }

    /// Move all contents of this record to another.
    func moveContents(to target: CDRecord) {
        if let contents {
            for object in contents {
                removeFromContents(object)
                target.addToContents(object)
            }
        }
    }
    
    /// Replace this object with another one.
    /// We move all our properties and content links to the other object.
    /// Then we update any object that pointed to us to point at the other object instead.
    func replaceWith(_ target: CDRecord) {
        moveProperties(to: target)
        moveContents(to: target)

        if let containedBy {
            for object in containedBy {
                object.addToContents(target)
                target.removeFromContents(self)
            }
        }
    }
}
