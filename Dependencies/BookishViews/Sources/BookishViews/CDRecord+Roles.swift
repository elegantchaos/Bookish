// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-
//  Created by Sam Deane on 16/09/22.
//  All code (c) 2022 - present day, Elegant Chaos Limited.
// -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-

import Foundation
import ThreadExtensions

extension CDRecord {
    
    /// A combination of a record and a role.
    /// A record can be linked to another record in multiple roles. For example
    /// a person could be both author and illustrator of the same book.
    ///
    /// To show a list of all the links from a record, SwiftUI needs each list
    /// item to have a unique identifier. Since the same record might crop up
    /// multiple times, we can't just use the record id. Instead we need a
    /// combination of the record id and the role.
    struct RoleAndRecord: Identifiable {
        let role: CDRecord
        let record: CDRecord
        var id: String { "\(role).\(record.id)" }
    }
    

    /// The identifier to use for a role list for a given role
    func roleID(_ role: CDRecord) -> String {
        return "\(role.id).\(id)"
    }

    /// Add another record in a given role to this record
    func addLink(to record: CDRecord, role: CDRecord? = nil) {
        // make a link record
        let link = CDRecord.make(kind: .link, in: managedObjectContext!)
        link.addToContents(self)    // the link points to this item
        record.addToContents(link)  // the item being linked points to the link record
        role?.addToContents(link)  // if a role was passed, that also points to the link record

        // add the record to the list if necessary
        // we flag that this object will change, even though in fact it doesn't
        // because the roleRecord changes and views looking at this record might need
        // refreshing as a result
//            onMainQueue {
//                self.objectWillChange.send()
//            }
        
    }

    /// Remove a given role for another record from this record.
    func removeRole(_ role: CDRecord, of record: CDRecord) {
        // find the list for the given role
        let roleID = roleID(role)
        if let roleRecord = findChildWithID(roleID, kind: .link), roleRecord.contains(record) {
            onMainQueue {
                self.objectWillChange.send()
            }

            // remove record from the list
            roleRecord.removeFromContents(record)
            
            // if it's empty, remove the list too
            if roleRecord.contents?.count == 0 {
                managedObjectContext!.delete(roleRecord)
            }
        }
    }

    /// Return all link records pointing to this record.
    func linksTo() -> [CDRecord] {
        let linkRecords = containersWithKind(.link)
        return linkRecords
    }

    /// Return all the link records pointing from this record.
    func linksFrom() -> [CDRecord] {
        let linkRecords = contentsWithKind(.link)
        return linkRecords
    }

    /// Return the names of all the roles that a given record fulfils
    /// for this record.
    func roles(for record: CDRecord) -> [CDRecord] {
        let roleRecords = linksTo()                                 // lists of links to this record
            .compactMap { $0.containedBy }                          // filter anything without content
            .filter { $0.contains(record) }                         // keep the ones containing the record we're interested in
            .compactMap { $0.first { $0.kind == .role } }           // extract the linked roles
        
        return roleRecords
    }

    /// Return a list of the role/record pairs associated with this record.
    func linkedRecords() -> [RoleAndRecord] {
        var entries: [RoleAndRecord] = []
        for link in linksTo() {
            if let role = link.containersWithKind(.role).first, let target = link.containersExcludingKind(.role).first {
                entries.append(.init(role: role, record: target))
            }
        }
        
        return entries
    }
    
    var asLink: RoleAndRecord? {
        guard let role = containersWithKind(.role).first, let target = containersExcludingKind(.role).first else { return nil }
        return RoleAndRecord(role: role, record: target)
    }
}
