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
    func addRole(_ role: CDRecord, for record: CDRecord) {
        // find the list for the given role
        let roleID = roleID(role)
        let roleRecord = findOrMakeChildWithID(roleID, kind: .roleList) { created in
            created.name = "\(self.name) \(role.name)s"
            role.addToContents(created)
        }

        // add the record to the list if necessary
        // we flag that this object will change, even though in fact it doesn't
        // because the roleRecord changes and views looking at this record might need
        // refreshing as a result
        if !roleRecord.contains(record) {
            onMainQueue {
                self.objectWillChange.send()
            }
            roleRecord.addToContents(record)
        }
        
    }

    /// Remove a given role for another record from this record.
    func removeRole(_ role: CDRecord, of record: CDRecord) {
        // find the list for the given role
        let roleID = roleID(role)
        if let roleRecord = findChildWithID(roleID, kind: .roleList), roleRecord.contains(record) {
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

    /// Return all the role lists for this record.
    func roleLists() -> [CDRecord] {
        let roleRecords = childredWithKind(.roleList)
        return roleRecords
    }

    /// Return the names of all the roles that a given record fulfils
    /// for this record.
    func roles(for record: CDRecord) -> [CDRecord] {
        let roleRecords = roleLists()                               // lists of roles for this record
            .filter { $0.contents?.contains(record) ?? false }      // just the ones containing the passed in record
            .compactMap { $0.containedBy }                          // each role list should be contained by a role record
            .flatMap { $0 }                                         // set of all containing records
            .filter { $0.kind == .role }                            // just the role ones
        
        return roleRecords
    }

    /// Return a list of the role/record pairs associated with this record.
    func roles() -> [RoleAndRecord] {
        var entries: [RoleAndRecord] = []
        for roleList in roleLists() {
            if let recordsInRole = roleList.contents {
                if let role = roleList.containersWithKind(.role).first {
                    for record in recordsInRole {
                        entries.append(.init(role: role, record: record))
                    }
                }
            }
        }
        
        return entries
    }
    

}
